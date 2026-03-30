require "spec_helper"
require "generators/michel/view/view_generator"

RSpec.describe Michel::Generators::ViewGenerator, :generator do
  context "When the resource, booking, and availability classes exist" do
    before(:all) do
      create_physician_models
      Michel.setup do |config|
        config.resource_class_name = "Physician"
        config.booking_class_name = "Appointment"
        config.availability_class_name = "PhysicianAvailability"
      end
      Rails::Generators.invoke("michel:view")

      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate
      Rails.autoloaders.main.reload
    end

    after(:all) do
      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).rollback(5)
      Rails::Generators.invoke("michel:view", [], behavior: :revoke)
      Rails.autoloaders.main.reload
    end

    it "generates available time slots" do
      doctor = Physician.create!(name: "Dr. Seuss")

      PhysicianAvailability.create!(
        physician: doctor,
        weekday: Date.tomorrow.wday, # ensures it aligns with tomorrow
        start_time: "09:00",
        end_time: "10:00",
        timezone: "UTC"
      )

      AvailableTimeSlot.refresh
      slots = AvailableTimeSlot.all

      expect(slots).not_to be_empty
      expect(slots.first.start_time.hour).to eq(9)
    end

    it "excludes slots that overlap with a booking" do
      doctor = Physician.create!(name: "Dr. Seuss")
      PhysicianAvailability.create!(
        physician: doctor,
        weekday: Date.tomorrow.wday, # ensures it aligns with tomorrow
        start_time: "09:00",
        end_time: "10:00",
        timezone: "UTC"
      )

      # Book a 30min slot at 9:00
      Appointment.create!(
        physician: doctor,
        start_time: Date.tomorrow.beginning_of_day + 9.hours,
        duration: 30
      )

      AvailableTimeSlot.refresh

      # Now the 9:00 slot should not be available
      slot_times = AvailableTimeSlot.pluck(:start_time)
      expect(slot_times).not_to include(Date.tomorrow.beginning_of_day + 9.hours)
    end
  end

  context "When the resource, booking, and availability do not exist" do
    before(:all) do
      Michel.setup do |config|
        config.resource_class_name = "Provider"
        config.booking_class_name = "Consult"
        config.availability_class_name = "ProviderAvailability"
      end
      Rails::Generators.invoke("michel:view")

      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate
      Rails.autoloaders.main.reload
    end

    after(:all) do
      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).rollback(5)
      Rails::Generators.invoke("michel:view", [], behavior: :revoke)
      Rails.autoloaders.main.reload
    end

    it "creates resource, booking, and availability classes" do
      expect(Object.const_defined?(Michel.resource_class_name))
      expect(Object.const_defined?(Michel.booking_class_name))
      expect(Object.const_defined?(Michel.availability_class_name))
    end

    it "generates available time slots" do
      doctor = Provider.create!(name: "Dr. Seuss")

      ProviderAvailability.create!(
        provider: doctor,
        weekday: Date.tomorrow.wday, # ensures it aligns with tomorrow
        start_time: "09:00",
        end_time: "10:00",
        timezone: "UTC"
      )

      AvailableTimeSlot.refresh
      slots = AvailableTimeSlot.all

      expect(slots).not_to be_empty
      expect(slots.first.start_time.hour).to eq(9)
    end

    it "excludes slots that overlap with a booking" do
      doctor = Provider.create!(name: "Dr. Seuss")
      ProviderAvailability.create!(
        provider: doctor,
        weekday: Date.tomorrow.wday, # ensures it aligns with tomorrow
        start_time: "09:00",
        end_time: "10:00",
        timezone: "UTC"
      )

      # Book a 30min slot at 9:00
      Consult.create!(
        provider: doctor,
        start_time: Date.tomorrow.beginning_of_day + 9.hours,
        duration: 30
      )

      AvailableTimeSlot.refresh

      # Now the 9:00 slot should not be available
      slot_times = AvailableTimeSlot.pluck(:start_time)
      expect(slot_times).not_to include(Date.tomorrow.beginning_of_day + 9.hours)
    end
  end

  def create_physician_models
    Rails::Generators.invoke("model", [
      "Physician",
      "name:string",
      "--skip"
    ], destination_root: Rails.root)

    Rails::Generators.invoke("model", [
      "Appointment",
      "start_time:datetime",
      "duration:integer",
      "physician:references",
      "--skip"
    ], destination_root: Rails.root)

    Rails::Generators.invoke("model", [
      "PhysicianAvailability",
      "timezone:string",
      "weekday:integer",
      "start_time:string",
      "end_time:string",
      "physician:references",
      "--skip"
    ], destination_root: Rails.root)
  end
end
