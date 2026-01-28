# Michel

Find available time slots quickly with a materialized view.

## Usage

### Install Michel
    In order to run the migrations, you must also install Scenic
  `gem scenic`
   `gem michel`
   `rails generate michel:install`


### Configure
  Michel needs three existing classes to function:
  * Resource Class - The resource that is occupied by a booking, ex: Physician, Room, Instructor. This resource is assumed to be available for only one booking at a time. A resource has many bookings and many availabilities.
  * Booking Class - The event that is scheduled for a resource, ex: Appointment. The resource is unavailable for the duration of the booking. It is required to have the following attributes:
    * `start_time` - a DateTime indicating the start time of the booking.
    * `duration` - an integer representing the number of minutes the booking lasts.
    * a reference to the id of the resource class
  The booking class is also used to block off unavailable times. It is recommended that you have a booking type to distinguish between appointments and other events.
  * Availability Class - The weekly schedule during which a resource is available for a booking, which is required to have the following attributes:
    * `timezone` - a string representing the time zone in which the availability is configured, ex: 'UTC'
    * `weekday` - an integer representing the weekday, starting with Monday = 1
    * `start_time` -  a string representing the beginning time of the availability in the configured timezone in 24-hour format, ex: '09:00'
    * `end_time` -  a string representing the end time of the availability in the configured timezone in 24-hour format, ex: '017:00'
    * a reference to the id of the resource class
  There should be one availability record for each continuous block of available time during a week. For example, if a resource is available from 9-5, M-Th, with a 1 hour break from 12-1, that is represented by eight availabilities: one for each day from 9-12 and another for each day from 1-5.

  Configure the class names in `config/initializers/michel.rb`

### Run generator
  To generate the database view and necessary supporting code, run `rails generate michel:view`. This will:
    1. Generate a migration to add an index to the booking class table on the resource id and start_time.
    2. Generate a Scenic model for available time slots.
    3. Generate a sql file with the view to back the scenic model.
    4. Insert associations between the existing classes and the generated `AvailableTimeSlot` class.

  Once the generator is finished, run `rails db:migrate` to run the generated migrations.

### Start Scheduling.
  To find available time slots, search for matching `AvailableTimeSlots`. Each slot has a `start_time` and an `end_time` and belongs to an `availability` and a `resource`.

  To refresh the materialized view, run `AvailableTimeSlot.refresh`. The view should be refreshed when a booking is created, updated, or deleted, or when availability changes.

## Contributing

See the [CONTRIBUTING] document.
Thank you, [contributors]!

[CONTRIBUTING]: CONTRIBUTING.md
[contributors]: https://github.com/thoughtbot/michel/graphs/contributors

## License

Michel is Copyright (c) thoughtbot, inc.
It is free software, and may be redistributed
under the terms specified in the [LICENSE] file.

[LICENSE]: /LICENSE

<!-- START /templates/footer.md -->
<!-- END /templates/footer.md -->
