module Weather
  class HourlyNormalizer
    def initialize(classifier: Classifier.new)
      @classifier = classifier
    end

    def call(payload, provider:, location:)
      data = payload.deep_symbolize_keys
      classification = @classifier.call(
        code: data.fetch(:weather_code),
        temperature_max_c: data.fetch(:temperature_c),
        precipitation_probability: data.fetch(:precipitation_probability, 0)
      )
      zone = Time.find_zone!(location.timezone.presence || "UTC")

      {
        forecast_at: zone.parse(data.fetch(:time).to_s).utc,
        provider:,
        condition_code: data.fetch(:weather_code).to_s,
        condition_label: classification.condition_label,
        weather_class: classification.weather_class,
        activity_context: classification.activity_context,
        temperature_c: data.fetch(:temperature_c),
        precipitation_probability: data.fetch(:precipitation_probability, 0),
        precipitation_mm: data.fetch(:precipitation_mm, 0),
        wind_speed_kph: data.fetch(:wind_speed_kph, 0),
        daylight: ActiveModel::Type::Boolean.new.cast(data.fetch(:daylight, false)),
        raw_data: data,
        fetched_at: Time.current
      }
    end
  end
end
