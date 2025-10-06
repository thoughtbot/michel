class CreateAppointments < ActiveRecord::Migration[8.0]
  def change
    create_table :appointments do |t|
      t.references :physician
      t.datetime :start_time, null: false
      t.integer :duration, null: false         # minutes
      t.timestamps
    end
  end
end
