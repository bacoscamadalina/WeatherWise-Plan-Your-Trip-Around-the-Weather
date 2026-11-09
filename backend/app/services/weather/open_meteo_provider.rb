module Weather
  class OpenMeteoProvider < Provider
    ENDPOINT = "https://api.open-meteo.com/v1/forecast"
    DAILY_FIELDS = %w[
      weather_code
      temperature_2m_min
      temperature_2m_max
      precipitation_probability_max
      precipitation_sum
      wind_speed_10m_max
      uv_index_max
      sunrise
      sunset
      daylight_duration
    ].freeze
    CURRENT_FIELDS = %w[
      temperature_2m
      apparent_temperature
      precipitation
      weather_code
      wind_speed_10m
      is_day
    ].freeze
    HOURLY_FIELDS = %w[
      temperature_2m
      precipitation_probability
      precipitation
      weather_code
      wind_speed_10m
      is_day
    ].freeze

    def initialize(client: ExternalApi::HttpClient.new)
      @client = client
    end

    def daily_forecast(location:, days: 14)
      payload = @client.get_json(daily_uri(location, days))
      daily = payload.fetch("daily")
      dates = daily.fetch("time")
      current = normalize_current(payload["current"])

      dates.each_index.map do |index|
        forecast = {
          date: dates.fetch(index),
          weather_code: value(daily, "weather_code", index),
          temperature_min_c: value(daily, "temperature_2m_min", index),
          temperature_max_c: value(daily, "temperature_2m_max", index),
          precipitation_probability: value(daily, "precipitation_probability_max", index, 0),
          precipitation_mm: value(daily, "precipitation_sum", index, 0),
          wind_speed_kph: value(daily, "wind_speed_10m_max", index, 0),
          uv_index_max: value(daily, "uv_index_max", index),
          sunrise_local: value(daily, "sunrise", index),
          sunset_local: value(daily, "sunset", index),
          daylight_duration_seconds: value(daily, "daylight_duration", index)
        }
        forecast[:current] = current if current&.fetch(:time, "")&.start_with?(dates.fetch(index))
        forecast
      end
    rescue KeyError, IndexError => error
      raise ExternalApi::Error, "Open-Meteo forecast payload is incomplete: #{error.message}"
    end

    def hourly_forecast(location:, date:)
      hourly_forecast_range(location:, start_date: date, end_date: date)
    end

    def hourly_forecast_range(location:, start_date:, end_date:)
      payload = @client.get_json(hourly_uri(location, start_date, end_date))
      hourly = payload.fetch("hourly")
      times = hourly.fetch("time")

      times.each_index.map do |index|
        {
          time: times.fetch(index),
          weather_code: value(hourly, "weather_code", index),
          temperature_c: value(hourly, "temperature_2m", index),
          precipitation_probability: value(hourly, "precipitation_probability", index, 0),
          precipitation_mm: value(hourly, "precipitation", index, 0),
          wind_speed_kph: value(hourly, "wind_speed_10m", index, 0),
          daylight: value(hourly, "is_day", index, 0) == 1
        }
      end
    rescue KeyError, IndexError => error
      raise ExternalApi::Error, "Open-Meteo hourly payload is incomplete: #{error.message}"
    end

    private

    def daily_uri(location, days)
      URI(ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(
          latitude: location.latitude,
          longitude: location.longitude,
          current: CURRENT_FIELDS.join(","),
          daily: DAILY_FIELDS.join(","),
          timezone: location.timezone.presence || "auto",
          forecast_days: days.to_i.clamp(1, 14)
        )
      end
    end

    def hourly_uri(location, start_date, end_date)
      URI(ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(
          latitude: location.latitude,
          longitude: location.longitude,
          hourly: HOURLY_FIELDS.join(","),
          timezone: location.timezone.presence || "auto",
          start_date: start_date.iso8601,
          end_date: end_date.iso8601
        )
      end
    end

    def value(daily, key, index, fallback = nil)
      daily.fetch(key).fetch(index) || fallback
    end

    def normalize_current(current)
      return if current.blank?

      {
        time: current.fetch("time"),
        temperature_c: current.fetch("temperature_2m"),
        apparent_temperature_c: current.fetch("apparent_temperature"),
        precipitation_mm: current.fetch("precipitation", 0),
        weather_code: current.fetch("weather_code"),
        wind_speed_kph: current.fetch("wind_speed_10m", 0),
        daylight: current.fetch("is_day", 0) == 1
      }
    end
  end
end
