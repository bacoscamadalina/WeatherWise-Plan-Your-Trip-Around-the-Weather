class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :country_code, null: false, limit: 2
      t.string :admin_area
      t.decimal :latitude, null: false, precision: 10, scale: 7
      t.decimal :longitude, null: false, precision: 10, scale: 7
      t.string :timezone, null: false, default: "UTC"
      t.string :provider, null: false
      t.string :external_id, null: false
      t.timestamps
    end

    add_index :locations, %i[provider external_id], unique: true
    add_index :locations, %i[latitude longitude]
  end
end
