class HourlyForecast < ApplicationRecord
  belongs_to :daily_forecast

  validates :forecast_at, :provider, :condition_code, :condition_label,
    :weather_class, :activity_context, :temperature_c, :fetched_at, presence: true
  validates :weather_class, inclusion: { in: DailyForecast::WEATHER_CLASSES }
  validates :activity_context, inclusion: { in: DailyForecast::ACTIVITY_CONTEXTS }
  validates :precipitation_probability, numericality: { in: 0..100 }
end
