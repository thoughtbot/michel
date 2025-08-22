require "rails/generators"
require "scenic"

module Michel
  class MichelGenerator < Rails::Generators::Base
    include Scenic
    source_root File.expand_path("templates", __dir__)

    def create_index_in_migration
      puts "Generating #{Michel.booking_class_table_name} index migration"
      invoke "migration", ["add_index_to_#{Michel.booking_class_table_name}"]
      index_migration_content = template_content("index_migration.erb")
      Dir.glob("db/migrate/*add_index_to_#{Michel.booking_class_table_name}.rb").each do |file|
        inject_into_file file, index_migration_content, after: "def change"
      end
    end

    def create_scenic_model
      puts "Creating scenic model available_time_slot"
      invoke "scenic:model", ["available_time_slot"], {"materialized" => true, "test_framework" => false}
    end

    def create_sql_file
      puts "Creating materialized view SQL at db/views/available_time_slots_v01.sql"
      template "view.erb", "db/views/available_time_slots_v01.sql", {force: true}
    end

    def add_associations_to_models
      has_many_associations = template_content("has_many_associations.erb")

      inject_into_class "app/models/#{Michel.availability_class_underscore}.rb", Michel.availability_class_name,
        has_many_associations
      inject_into_class "app/models/#{Michel.resource_class_underscore}.rb", Michel.resource_class_name,
        has_many_associations
      belongs_to_associations = template_content("belongs_to_associations.erb")
      case behavior
      when :invoke
        inject_into_class "app/models/available_time_slot.rb", "AvailableTimeSlot", belongs_to_associations
      end
    end

    private

    def template_content(filename)
      template = File.read(File.join(self.class.source_root, filename))
      ERB.new(template).result(binding)
    end
  end
end
