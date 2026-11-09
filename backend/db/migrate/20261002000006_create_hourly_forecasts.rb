class CreateHourlyForecasts < ActiveRecord::Migration[8.1]
  def change
    create_table :hourly_forecasts do |t|
      t.references :daily_forecast, null: false, foreign_key: true
      t.datetime :forecast_at, null: false
      t.string :provider, null: false
      t.string :condition_code, null: false
      t.string :condition_label, null: false
      t.string :weather_class, null: false
      t.string :activity_context, null: false
      t.decimal :temperature_c, null: false, precision: 5, scale: 2
      t.integer :precipitation_probability, null: false, default: 0
      t.decimal :precipitation_mm, null: false, precision: 7, scale: 2, default: 0
      t.decimal :wind_speed_kph, null: false, precision: 6, scale: 2, default: 0
      t.boolean :daylight, null: false, default: false
      t.jsonb :raw_data, null: false, default: {}
      t.datetime :fetched_at, null: false
      t.timestamps
    end

    add_index :hourly_forecasts, %i[daily_forecast_id forecast_at provider],
      unique: true, name: "index_hourly_forecasts_on_daily_time_provider"
  end
end
