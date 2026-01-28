require "spec_helper"
require "generators/michel/view/view_generator"

RSpec.describe Michel::Generators::ViewGenerator, :generator do
  before(:all) do
    Michel.setup do |config|
      config.resource_class_name = "Physician"
      config.booking_class_name = "Appointment"
      config.availability_class_name = "PhysicianAvailability"
    end

    run_generator
    Scenic.load

    ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate
    Rails.autoloaders.main.reload
  end

  after(:all) do
    ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).rollback(2)
    run_generator [], behavior: :revoke
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
