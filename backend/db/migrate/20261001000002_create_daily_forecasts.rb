class CreateDailyForecasts < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_forecasts do |t|
      t.references :location, null: false, foreign_key: true
      t.date :forecast_date, null: false
      t.string :provider, null: false
      t.string :condition_code, null: false
      t.string :condition_label, null: false
      t.string :weather_class, null: false
      t.string :activity_context, null: false
      t.decimal :temperature_min_c, null: false, precision: 5, scale: 2
      t.decimal :temperature_max_c, null: false, precision: 5, scale: 2
      t.integer :precipitation_probability, null: false, default: 0
      t.decimal :precipitation_mm, null: false, precision: 7, scale: 2, default: 0
      t.decimal :wind_speed_kph, null: false, precision: 6, scale: 2, default: 0
      t.jsonb :raw_data, null: false, default: {}
      t.datetime :fetched_at, null: false
      t.timestamps
    end

    add_index :daily_forecasts, %i[location_id forecast_date provider],
      unique: true, name: "index_daily_forecasts_on_location_date_provider"
  end
end
