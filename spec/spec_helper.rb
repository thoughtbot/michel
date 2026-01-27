# frozen_string_literal: true

Dir.glob("#{__dir__}/support/**/*.rb").each { |f| require f }
require File.expand_path("../../spec/example-app/config/environment", __FILE__)
require "michel"
require "scenic"
require "ammeter/init"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.around(:each) do |example|
    ActiveRecord::SchemaMigration
      .new(ActiveRecord::Tasks::DatabaseTasks.migration_connection_pool)
      .create_table

    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end
end
