class AddSunExposureToDailyForecasts < ActiveRecord::Migration[8.1]
  def change
    change_table :daily_forecasts, bulk: true do |table|
      table.decimal :uv_index_max, precision: 5, scale: 2
      table.string :sunrise_local
      table.string :sunset_local
      table.integer :daylight_duration_seconds
    end
  end
end
