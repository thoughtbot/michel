require "zeitwerk"
require "michel/railtie" if defined?(Rails)

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.setup
module Michel
  class Error < StandardError; end

  mattr_accessor :resource_class_name
  mattr_accessor :booking_class_name
  mattr_accessor :availability_class_name

  def self.setup
    yield self
  end

  def self.resource_class_symbol
    @@resource_class_name.underscore.to_sym
  end

  def self.resource_class_foreign_id
    @@resource_class_name.foreign_key
  end

  def self.resource_class_underscore
    @@resource_class_name.underscore
  end

  def self.booking_class_symbol
    @@booking_class_name.underscore.to_sym
  end

  def self.booking_class_table_name
    @@booking_class_name.tableize
  end

  def self.booking_class_foreign_id
    @@booking_class_name.foreign_key
  end

  def self.booking_class_underscore
    @@booking_class_name.underscore
  end

  def self.availability_class_symbol
    @@availability_class_name.underscore.to_sym
  end

  def self.availability_class_table_name
    @@availability_class_name.tableize
  end

  def self.availability_class_foreign_id
    @@availability_class_name.foreign_key
  end

  def self.availability_class_underscore
    @@availability_class_name.underscore
  end
end
