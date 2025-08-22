require "rails/generators"
require "scenic"

module Michel
  class MichelGenerator < Rails::Generators::Base
    include Scenic
    source_root File.expand_path("templates", __dir__)

    def create_index_in_migration
      puts "Generating #{Michel.booking_class_table_name} index migration"
      invoke "migration", ["add_index_to_#{Michel.booking_class_table_name}"]
      Dir.glob("db/migrate/*add_index_to_#{Michel.booking_class_table_name}.rb").each do |file|
        insert_into_file file, after: "def change" do
          <<~RUBY
            \nreversible do |direction|
              direction.up do
                execute <<-SQL
                  CREATE EXTENSION btree_gist;
                  CREATE INDEX on #{Michel.booking_class_table_name} using gist (#{Michel.resource_class_foreign_id}, tsrange(start_time, start_time + interval '1 minute' * duration, '()'));
                SQL
              end
              direction.down do
                execute <<-SQL
                  DROP INDEX #{Michel.booking_class_table_name}_#{Michel.resource_class_foreign_id}_tsrange_idx;
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
      invoke "scenic:model", ["available_time_slot"], {"materialized" => true}
    end

    def create_sql_file
      puts "Creating materialized view SQL at db/views/available_time_slots_v01.sql"
      template "view.erb", "db/views/available_time_slots_v01.sql", {force: true}
    end

    def add_associations_to_models
      inject_into_class "app/models/#{Michel.availability_class_underscore}.rb", Michel.availability_class_name.classify do
        <<-RUBY
  has_many :available_time_slots
        RUBY
      end

      inject_into_class "app/models/#{Michel.resource_class_underscore}.rb", Michel.resource_class_name.classify do
        <<-RUBY
  has_many :available_time_slots
        RUBY
      end

      case behavior
      when :invoke
        inject_into_class "app/models/available_time_slot.rb", "AvailableTimeSlot" do
          <<-RUBY
  belongs_to :#{Michel.availability_class_underscore}
  belongs_to :#{Michel.resource_class_underscore}
          RUBY
        end
      end
    end
  end
end
