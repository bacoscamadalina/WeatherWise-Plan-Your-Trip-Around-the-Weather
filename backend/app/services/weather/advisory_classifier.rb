module Weather
  Advisory = Data.define(:code, :severity, :title, :message)

  class AdvisoryClassifier
    MAX_ADVISORIES = 2
    SEVERITY_ORDER = { "high" => 0, "moderate" => 1 }.freeze

    def call(forecast)
      advisories = [
        condition_advisory(forecast),
        rain_advisory(forecast),
        wind_advisory(forecast),
        temperature_advisory(forecast),
        uv_advisory(forecast)
      ].compact

      advisories
        .uniq(&:code)
        .sort_by { |advisory| SEVERITY_ORDER.fetch(advisory.severity) }
        .first(MAX_ADVISORIES)
    end

    private

    def condition_advisory(forecast)
      case forecast.weather_class
      when "extreme"
        advisory(
          "extreme_weather",
          "high",
          "Severe conditions possible",
          "Keep plans flexible and check official local warnings before leaving."
        )
      when "storm"
        advisory(
          "storm",
          "high",
          "Storm risk",
          "Prefer sheltered plans and check official local warnings before travelling."
        )
      when "snow"
        advisory(
          "snow",
          "moderate",
          "Snow may affect travel",
          "Allow extra travel time and confirm routes before setting out."
        )
      when "fog"
        advisory(
          "low_visibility",
          "moderate",
          "Low visibility possible",
          "Allow extra travel time, especially early or late in the day."
        )
      end
    end

    def rain_advisory(forecast)
      amount = forecast.precipitation_mm.to_f
      probability = forecast.precipitation_probability.to_i
      return if amount < 5 || probability < 70

      if amount >= 15 || probability >= 90
        advisory(
          "heavy_rain",
          "high",
          "Heavy rain likely",
          "Choose weather-proof plans and allow extra time for local travel."
        )
      else
        advisory(
          "rain",
          "moderate",
          "A wet part of the day",
          "Keep an indoor alternative ready and check the hourly forecast before leaving."
        )
      end
    end

    def wind_advisory(forecast)
      speed = forecast.wind_speed_kph.to_f
      return if speed < 40

      if speed >= 60
        advisory(
          "very_strong_wind",
          "high",
          "Very strong wind",
          "Avoid exposed outdoor routes and check official local warnings."
        )
      else
        advisory(
          "strong_wind",
          "moderate",
          "Strong wind",
          "Prefer sheltered routes and reconsider exposed outdoor activities."
        )
      end
    end

    def temperature_advisory(forecast)
      if forecast.temperature_max_c.to_f >= 35
        advisory(
          "high_heat",
          "high",
          "Very hot conditions",
          "Move demanding outdoor plans away from the hottest part of the day."
        )
      elsif forecast.temperature_min_c.to_f <= -10
        advisory(
          "severe_cold",
          "high",
          "Severe cold",
          "Limit long outdoor plans and confirm local travel conditions."
        )
      end
    end

    def uv_advisory(forecast)
      uv_index = forecast.uv_index_max&.to_f
      return if uv_index.nil? || uv_index < 8

      if uv_index >= 11
        advisory(
          "extreme_uv",
          "high",
          "Extreme UV exposure",
          "Avoid long exposed plans around midday and check local sun-protection guidance."
        )
      else
        advisory(
          "very_high_uv",
          "moderate",
          "Very high UV exposure",
          "Favor shade around midday and include sun protection in outdoor plans."
        )
      end
    end

    def advisory(code, severity, title, message)
      Advisory.new(code:, severity:, title:, message:)
    end
  end
end
