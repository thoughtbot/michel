require "rails/generators/base"
require "scenic"
module Michel
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_initializer
        copy_file "michel.rb", "config/initializers/michel.rb"
      end
    end
  end
end
