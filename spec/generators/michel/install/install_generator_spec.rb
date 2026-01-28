require "spec_helper"
require "generators/michel/install/install_generator"

RSpec.describe Michel::Generators::InstallGenerator, :generator do
  it "generates initializer file" do
    destination File.expand_path("../../../../../tmp", __FILE__)
    prepare_destination

    run_generator
    initializer = file("config/initializers/michel.rb")

    # is_expected_to contain - verifies the file's contents
    expect(initializer).to contain(/Michel.setup do |config|/)
    expect(initializer).to contain(/config.resource_class_name = "Resource"/)
    expect(initializer).to contain(/config.booking_class_name = "Booking"/)
    expect(initializer).to contain(/config.availability_class_name = "Availability"/)
  end
end
