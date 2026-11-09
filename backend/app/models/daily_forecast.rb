class DailyForecast < ApplicationRecord
  WEATHER_CLASSES = %w[clear cloudy rain snow storm fog extreme].freeze
  ACTIVITY_CONTEXTS = %w[indoor outdoor flexible caution].freeze

  belongs_to :location
  has_many :hourly_forecasts, dependent: :destroy
  has_many :trip_days, dependent: :nullify

  validates :forecast_date, :provider, :condition_code, :condition_label,
    :weather_class, :activity_context, :temperature_min_c,
    :temperature_max_c, :fetched_at, presence: true
  validates :weather_class, inclusion: { in: WEATHER_CLASSES }
  validates :activity_context, inclusion: { in: ACTIVITY_CONTEXTS }
  validates :precipitation_probability, numericality: { in: 0..100 }
  validates :uv_index_max, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :daylight_duration_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
