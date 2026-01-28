def down
  drop_view :available_time_slots, materialized: true
end
