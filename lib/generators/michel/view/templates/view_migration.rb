  unless defined?(Scenic)
    raise "Scenic gem must be included in the Gemfile to run this migration"
  end
  def down
    drop_view :available_time_slots, materialized: true
  end

  