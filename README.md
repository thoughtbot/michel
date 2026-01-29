# Michel

A generator for creating a materialized-view-backed model for querying available time slots. Inspired by and tailored for health care applications that need self-scheduling capability for users. Named for the worst scheduling assistant on tv, [Michel Gerard of Gilmore Girls.](https://gilmoregirls.fandom.com/wiki/Michel_Gerard)


## The problem
When scheduling things like doctor's appointments, hair cuts, or conference room bookings, answering "Is Dr. Doolittle available at this time?" is fairly straightforward. You can query whether there are existing appointments overlapping the time you're looking at, which is fairly quick to do with a well-indexed database.

Answering the same question for multiple doctors, stylists, or conference rooms - "Who is available at this time" - is slightly more complex, but still manageable with standard database query methods.

When building an app that allows self-scheduling, the question you really want to ask it "what resources are available at what times during this time period?"  This is a more complicated query. Finding available time slots using Ruby is painfully slow. Postgres has some powerful capabilities that can help us, though.

## The solution

Michel helps create a materialized database view for answering this question, using the power of [Scenic](https://github.com/scenic-views/scenic) and [Postgres](https://www.postgresql.org/). Postgres has powerful tools for querying time ranges and finding overlaps.  You tell Michel the class name of your resource (doctor, stylist, conference room, etc), the class name of your booking (appointment, reservation, etc) and the class name of your availability model and Michel creates a materialized view-backed model called `AvailableTimeSlot`.

These available time slots have start times every 15 minutes for 30 minute durations during times the resource is not already booked. The view currently calculates time slots for the next six months. In the future, this range will be configurable.

For example, a doctor who works 9am-12pm Eastern on Mondays would have the following available 30-minute time slots for the first full week of 2026:

* Monday, Jan 5, 2026, 9:00am EST
* Monday, Jan 5, 2026, 9:15am EST
* Monday, Jan 5, 2026, 9:30am EST
* Monday, Jan 5, 2026, 9:45am EST
* Monday, Jan 5, 2026, 10:00am EST
* Monday, Jan 5, 2026, 10:15am EST
* Monday, Jan 5, 2026, 10:30am EST
* Monday, Jan 5, 2026, 10:45am EST
* Monday, Jan 5, 2026, 11:00am EST
* Monday, Jan 5, 2026, 11:15am EST
* Monday, Jan 5, 2026, 11:30am EST

If they then scheduled a 30-minute appointment on Jan 5, 2026 starting at 9:45, the refreshed availability would be:
* Monday, Jan 5, 2026, 9:00am EST
* Monday, Jan 5, 2026, 9:15am EST
* Monday, Jan 5, 2026, 10:15am EST
* Monday, Jan 5, 2026, 10:30am EST
* Monday, Jan 5, 2026, 10:45am EST
* Monday, Jan 5, 2026, 11:00am EST
* Monday, Jan 5, 2026, 11:15am EST
* Monday, Jan 5, 2026, 11:30am EST

An appointment that ends at 10:15 and an appointment that begins at 10:15 are considered to be consecutive, not overlapping.

More details on what an availability record looks like are in the Configure section.

## Limitations

The materialized view is stored in the database and it is not a trivial size. Michel favors increasing database storage over database or application processing. If limiting database size is a higher priority than finding available time slots quickly, this is not the right tool for you. In our experience, it's cheaper and easier to scale up a database than to lose users waiting for time slots to load.

Currently, only the class names and the attributes stored on availabilities are customizable.  Start times are every 15 minutes and the total range of time slots is 6 months from the current date. More configuration options will be available in the future.

The materialized view must be refreshed every time a booking or availability is created, modified, or deleted. For most applications that involve self-scheduling, a user queries the availability much more often than a booking is created or a schedule is changed, so it is much more efficient to materialize the view and refresh it regularly than to have a non-materialized view that is queried on every search.

All bookings are considered to be blocking. In order to make a time slot available, the booking must be destroyed. In the future, we intend to add a way to configure status values that are non-blocking for things like cancelled appointments where you'd like to keep the record but want the resource to be available.

Available time slots each have a 30-minute duration. This will be configurable in the future. Bookings can be any duration.

Availabilities are for only one resource type right now. A doctor who works at two different clinics, for example, will not have a way to distinguish between availabilities at different clinics. In the future, we will add support for a second resource type, so a query for available time slots can be scoped to a second resource, like a clinic location. The current view allows for this scoping only by joining to the availability table and scoping that to the second resource, which is less efficient.

## Integration with an EHR

Michel was inspired while working on a health care app that integrated with an existing EHR. The EHR was able to provide appointment times and provider schedules, but not available time slots. Michel's materialized view helped us calculate those and ensure that providers weren't double-booked via both our application and staff booking directly in the EHR. In order to make sure the two systems stay in sync, it is necessary to:

* Update the application database with booking creations/changes/deletions from the EHR as they are made. Many EHRs use webhooks for this sort of synchronization.
* Update the EHR with booking creations/changes/deletions from the application as they are made. This is usually accomplished with an api endpoint provided by the EHR.
* Update the application database with availability creations/changes/deletions from the EHR as they are made. This is usually also a webhook.
* Refresh the materialized view when any of the above updates are made.
* Treat the EHR as the source of truth for both bookings and availabilities. Be careful about allowing modifications of resource availability from both the EHR and the application, as this can be tricky to keep in sync.

## Usage

### Install Michel
  In order to run the migrations, you must also install Scenic. Add to your gemfile:

  ``` ruby
  gem "michel"
  gem "scenic"
  ```

  Run `bundle install`, then  `rails generate michel:install`

### Configure
  Configure the class names in `config/initializers/michel.rb`. The default initializer is copied to your app when you run `rake michel:install` and looks like this:

  ``` ruby
  # config/initializers/michel.rb

  Michel.setup do |config|
    config.resource_class_name = "Resource"
    config.booking_class_name = "Booking"
    config.availability_class_name = "Availability"
  end
```
Replace the default class names with the class names from your app, if they differ, for example:

  ``` ruby
  # config/initializers/michel.rb

  Michel.setup do |config|
    config.resource_class_name = "ConferenceRoom"
    config.booking_class_name = "Reservation"
    config.availability_class_name = "RoomSchedule"
  end
```

  Michel expects three classes to exist in the application:
  * Resource Class
    * The resource that is occupied by a booking, ex: Physician, Room, Instructor.
    * This resource is assumed to be available for only one booking at a time. A resource has many bookings and many availabilities.

  * Booking Class
    * The event that is scheduled for a resource, ex: Appointment.
    * The resource is unavailable for the duration of the booking.
    * It is required to have the following attributes:
      * `start_time` - a DateTime indicating the start time of the booking.
      * `duration` - an integer representing the number of minutes the booking lasts.
      * a reference to the id of the resource class
    * The booking class is also used to block off unavailable times. It is recommended that you have a booking type to distinguish between appointments and other events.
  * Availability Class
    * The weekly schedule during which a resource is available for a booking
    * It is required to have the following attributes:
      * `timezone` - a string representing the time zone in which the availability is configured, ex: 'UTC'
      * `weekday` - an integer representing the weekday, starting with Monday = 1
      * `start_time` -  a string representing the beginning time of the availability in the configured timezone in 24-hour format, ex: '09:00'
      * `end_time` -  a string representing the end time of the availability in the configured timezone in 24-hour format, ex: '017:00'
      * a reference to the id of the resource class
    * There should be one availability record for each continuous block of available time during a week. For example, if a resource is available from 9-5, M-Th, with a 1 hour break from 12-1, that is represented by eight availabilities: one for each day from 9-12 and another for each day from 1-5.


### Run the generator
  To generate the database view and necessary supporting code, run `rails generate michel:view`. This will:

  1. Generate a migration to add an index to the booking class table on the resource id and start_time.
  2. Generate a Scenic model for available time slots.
  3. Generate a sql file with the view to back the scenic model.
  4. Insert associations between the existing classes and the generated `AvailableTimeSlot` class.

  Once the generator is finished, run `rails db:migrate` to run the generated migrations.

### Start querying for Available Time Slots
  The `AvailableTimeSlot` class stores the generated time slots that don't overlap with existing bookings.
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
