class CreateAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :physician_availabilities do |t|
      t.references :physician
      t.integer :weekday, null: false          # 1 = Monday, etc
      t.string :start_time, null: false       # '09:00'
      t.string :end_time, null: false         # '17:00'
      t.string :timezone, null: false         # e.g. 'UTC'
      t.timestamps
    end
  end
end
