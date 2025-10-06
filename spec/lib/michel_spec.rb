require "michel"
RSpec.describe Michel do
  before do
    Michel.setup do |config|
      config.resource_class_name = "Physician"
      config.booking_class_name = "Appointment"
      config.availability_class_name = "PhysicianAvailability"
    end
  end

  describe "resource helpers" do
    it "returns correct symbol" do
      expect(Michel.resource_class_symbol).to eq(:physician)
    end

    it "returns correct foreign key" do
      expect(Michel.resource_class_foreign_id).to eq("physician_id")
    end

    it "returns correct underscored name" do
      expect(Michel.resource_class_underscore).to eq("physician")
    end
  end

  describe "booking helpers" do
    it "returns correct symbol" do
      expect(Michel.booking_class_symbol).to eq(:appointment)
    end

    it "returns correct table name" do
      expect(Michel.booking_class_table_name).to eq("appointments")
    end

    it "returns correct foreign key" do
      expect(Michel.booking_class_foreign_id).to eq("appointment_id")
    end

    it "returns correct underscored name" do
      expect(Michel.booking_class_underscore).to eq("appointment")
    end
  end

  describe "availability helpers" do
    it "returns correct symbol" do
      expect(Michel.availability_class_symbol).to eq(:physician_availability)
    end

    it "returns correct table name" do
      expect(Michel.availability_class_table_name).to eq("physician_availabilities")
    end

    it "returns correct foreign key" do
      expect(Michel.availability_class_foreign_id).to eq("physician_availability_id")
    end

    it "returns correct underscored name" do
      expect(Michel.availability_class_underscore).to eq("physician_availability")
    end
  end
end
