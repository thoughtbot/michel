class CreatePhysicians < ActiveRecord::Migration[8.0]
  def change
    create_table :physicians do |t|
      t.string :name
      t.timestamps
    end
  end
end
