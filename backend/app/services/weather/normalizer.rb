module Weather
  class Normalizer
    def initialize(classifier: Classifier.new)
      @classifier = classifier
    end

    def call(payload, provider:)
      data = payload.deep_symbolize_keys
      classification = @classifier.call(
        code: data.fetch(:weather_code),
        temperature_max_c: data.fetch(:temperature_max_c),
        precipitation_probability: data.fetch(:precipitation_probability, 0)
      )

      {
        forecast_date: Date.iso8601(data.fetch(:date).to_s),
        provider:,
        condition_code: data.fetch(:weather_code).to_s,
        condition_label: classification.condition_label,
        weather_class: classification.weather_class,
        activity_context: classification.activity_context,
        temperature_min_c: data.fetch(:temperature_min_c),
        temperature_max_c: data.fetch(:temperature_max_c),
        precipitation_probability: data.fetch(:precipitation_probability, 0),
        precipitation_mm: data.fetch(:precipitation_mm, 0),
        wind_speed_kph: data.fetch(:wind_speed_kph, 0),
        uv_index_max: data[:uv_index_max],
        sunrise_local: data[:sunrise_local],
        sunset_local: data[:sunset_local],
        daylight_duration_seconds: data[:daylight_duration_seconds],
        raw_data: data,
        fetched_at: Time.current
      }
    end
  end
end
