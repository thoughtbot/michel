# lib/michel/railtie.rb
module Michel
  class Railtie < Rails::Railtie
    initializer "michel.load_scenic" do
      require "scenic"
      require "scenic/statements"

      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Migration.include Scenic::Statements
      end
    end
  end
end
