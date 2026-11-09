class CreateTripPlanning < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :display_name
      t.jsonb :preferences, null: false, default: {}
      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    create_table :trips do |t|
      t.references :user, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :party_size, null: false, default: 1
      t.string :pace, null: false, default: "balanced"
      t.string :transport_mode, null: false, default: "car"
      t.decimal :max_distance_km, precision: 5, scale: 1, null: false, default: 50
      t.jsonb :preferences, null: false, default: {}
      t.string :status, null: false, default: "draft"
      t.timestamps
    end
    add_index :trips, %i[location_id starts_on ends_on]

    create_table :trip_days do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :daily_forecast, foreign_key: true
      t.date :date, null: false
      t.string :weather_class
      t.string :activity_context
      t.string :summary
      t.jsonb :weather_snapshot, null: false, default: {}
      t.timestamps
    end
    add_index :trip_days, %i[trip_id date], unique: true

    create_table :itinerary_items do |t|
      t.references :trip_day, null: false, foreign_key: true
      t.references :recommendation, foreign_key: true
      t.string :slot, null: false
      t.string :kind, null: false
      t.string :title, null: false
      t.text :summary
      t.string :venue_name
      t.time :starts_at
      t.time :ends_at
      t.decimal :distance_km, precision: 6, scale: 1
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :provider
      t.string :external_id
      t.string :url
      t.string :image_url
      t.decimal :rating, precision: 3, scale: 2
      t.integer :rating_count
      t.integer :position, null: false, default: 0
      t.string :status, null: false, default: "suggested"
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :itinerary_items, %i[trip_day_id position]
    add_index :itinerary_items, %i[provider external_id]
  end
end
