# frozen_string_literal: true

require_relative "michel/version"
require "michel/generators/michel_generator"

module Michel
  class Error < StandardError; end

  mattr_accessor :resource_class_name

  @@resource_class_name = "Resource"

  def self.setup
    yield self
  end
end
