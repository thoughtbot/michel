require 'rails/generators'

module Michel
  class MichelGenerator < Rails::Generators::Base
    def add_scenic_gem
      puts Michel.resource_class_name
      puts "Adding scenic gem to Gemfile"
      gem "scenic"
      Bundler.with_unbundled_env { run "bundle install" }
    end

    def create_index_in_migration
      puts "Generating bookings index migration"
      generate "migration", "add_index_to_bookings"
      Dir.glob("db/migrate/*add_index_to_bookings.rb").each do |file|
        insert_into_file file, after: "def change" do
          <<~RUBY
            \nreversible do |direction|
              direction.up do
                execute <<-SQL
                  CREATE EXTENSION btree_gist;
                  CREATE INDEX on bookings using gist (resource_id, tsrange(start_time, start_time + interval '1 minute' * duration, '()'));
                SQL
              end
              direction.down do
                execute <<-SQL
                  DROP INDEX bookings_resource_id_tsrange_idx;
                  DROP EXTENSION IF EXISTS btree_gist;
                SQL
              end
            end
          RUBY
        end
      end
    end

    def create_scenic_model
      puts "Creating scenic model available_time_slot"
      generate "scenic:model", "available_time_slot", "--materialized"
    end

    def create_sql_file
      puts "Creating materialized view SQL at db/views/available_time_slots_v01.sql"
      insert_into_file "db/views/available_time_slots_v01.sql" do
        <<~SQL
          WITH RECURSIVE time_slots AS (
            -- Generate a series of dates for the next year, starting from tomorrow
            SELECT
              p.id AS availability_id,
              p.resource_id,
              -- what is DATE_TRUNC?
              -- DATE_TRUNC('week', CURRENT_DATE) returns the first day of the week
              (DATE_TRUNC('week', CURRENT_DATE) + (p.weekday - 1 || ' days')::interval) AS start_date,
              CURRENT_DATE + INTERVAL '6 months' AS end_date,
              p.start_time,
              p.end_time,
              p.timezone
            FROM
              availabilities p
            UNION ALL
            -- Recursively generate dates for all instances of the given weekday
            SELECT
              ts.availability_id,
              ts.resource_id,
              ts.start_date + INTERVAL '1 week' AS start_date,  -- Explicitly alias the column
              ts.end_date,
              ts.start_time,
              ts.end_time,
              ts.timezone
            FROM
              time_slots ts
            WHERE
              ts.start_date + INTERVAL '1 week' <= ts.end_date
          ),
          -- Generate time slots for each day, every 15 minutes
          slot_intervals AS (
            SELECT
              ts.availability_id,
              ts.resource_id,
              ts.start_date,

              -- Create proper timestamps for start and end times with timezone handling
              (make_timestamptz(
                date_part('year', ts.start_date)::integer,
                date_part('month', ts.start_date)::integer,
                date_part('day', ts.start_date)::integer,
                split_part(ts.start_time, ':', 1)::int,
                split_part(ts.start_time, ':', 2)::int,
                0,
                ts.timezone
              )) AT TIME ZONE 'UTC' AS slot_start_time,

              (make_timestamptz(
                date_part('year', ts.start_date)::integer,
                date_part('month', ts.start_date)::integer,
                date_part('day', ts.start_date)::integer,
                split_part(ts.end_time, ':', 1)::int,
                split_part(ts.end_time, ':', 2)::int,
                0,
                ts.timezone
              )) AT TIME ZONE 'UTC' AS slot_end_time
            FROM
              time_slots ts
          ),
          time_slots_every_15_min AS (
            SELECT
              si.availability_id,
              si.resource_id,
              si.start_date,

              -- Generate the series for time slots every 15 minutes
              generate_series(
                GREATEST(si.slot_start_time, CURRENT_DATE + INTERVAL '1 day'),
                -- Ensure it starts from tomorrow
                si.slot_end_time - INTERVAL '30 minutes',
                INTERVAL '15 minutes'
              ) AS slot_start_time
            FROM
              slot_intervals si
          )
          SELECT
            concat(availability_id, slot_start_time) AS id,
            availability_id,
            resource_id,
            slot_start_time as start_time,
            slot_start_time + INTERVAL '30 minutes' AS end_time
          FROM
            time_slots_every_15_min
          EXCEPT
                      SELECT
                        concat(availability_id, slot_start_time) AS id,
                        time_slots_every_15_min.availability_id,
                        time_slots_every_15_min.resource_id,
                        time_slots_every_15_min.slot_start_time as start_time,
                        time_slots_every_15_min.slot_start_time + INTERVAL '30 minutes' AS end_time
                      FROM       time_slots_every_15_min
                      CROSS JOIN bookings
                      WHERE      tsrange(bookings.start_time, bookings.start_time + interval '1 minute' * bookings.duration, '()')
                                && tsrange(time_slots_every_15_min.slot_start_time, time_slots_every_15_min.slot_start_time + INTERVAL '30 minutes', '()')
                      AND bookings.resource_id = time_slots_every_15_min.resource_id

        SQL
      end
    end

    def add_associations_to_models
      insert_into_file "app/models/availability.rb", after: "class Availability < ApplicationRecord" do
        <<~RUBY
          \nhas_many :available_time_slots
        RUBY
      end

      insert_into_file "app/models/available_time_slot.rb", after: "class AvailableTimeSlot < ApplicationRecord" do
        <<~RUBY
          \nbelongs_to :availability
          \nbelongs_to :resource
        RUBY
      end

      insert_into_file "app/models/resource.rb", after: "class Resource < ApplicationRecord" do
        <<~RUBY
          \nhas_many :available_time_slots
        RUBY
      end
    end
  end
end
