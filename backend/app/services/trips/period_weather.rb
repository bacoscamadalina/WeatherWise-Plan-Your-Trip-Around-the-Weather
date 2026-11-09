module Trips
  class PeriodWeather
    SEVERITY = { "clear" => 0, "cloudy" => 1, "rain" => 2, "snow" => 3, "storm" => 4 }.freeze

    def initialize(hours:, period:, forecast:)
      @forecast = forecast
      @period = period
      @hours = Array(hours).select { |hour| overlaps_period?(hour) }
    end

    def payload
      @payload ||= @hours.any? ? hourly_payload : daily_payload
    end

    def safe_for?(recommendation)
      return true if recommendation.indoor? || recommendation.metadata["setting"] == "unknown"

      weather = payload
      return false if weather.fetch(:weather_class).in?(%w[rain snow storm])
      return false if weather.fetch(:precipitation_probability).to_i >= 50
      return false if weather.fetch(:wind_speed_kph).to_f >= 35

      case recommendation.metadata["weather_sensitivity"]
      when "dry_daylight"
        weather.fetch(:precipitation_probability).to_i <= 25 &&
          weather.fetch(:precipitation_mm).to_f <= 1 && weather.fetch(:daylight)
      when "outdoor_daylight"
        weather.fetch(:precipitation_probability).to_i <= 40 && weather.fetch(:daylight)
      else
        weather.fetch(:activity_context).in?(%w[outdoor flexible])
      end
    end

    def preference(recommendation)
      context = payload.fetch(:activity_context)
      return 0 if recommendation.metadata["setting"] == "unknown"
      return recommendation.indoor? ? 0 : 1 if context.in?(%w[indoor caution])

      recommendation.indoor? ? 1 : 0
    end

    def reason_for(recommendation, language: "en")
      weather = payload
      return unless weather.fetch(:source) == "hourly"

      romanian = language.to_s.start_with?("ro")
      interval = "#{@period.fetch(:starts_at)}–#{@period.fetch(:ends_at)}"
      rain = weather.fetch(:precipitation_probability).to_i
      wet = weather.fetch(:weather_class).in?(%w[rain snow storm]) || rain >= 50

      if recommendation.indoor? && wet
        return romanian ?
          "Între #{interval}, riscul de ploaie ajunge la #{rain}%; am ales o oprire la interior." :
          "Rain risk reaches #{rain}% between #{interval}, so this stop stays indoors."
      end
      if !recommendation.indoor? && safe_for?(recommendation)
        return romanian ?
          "Intervalul #{interval} este fereastra potrivită pentru exterior, cu cel mult #{rain}% risc de ploaie." :
          "The #{interval} window is suitable for outdoors, with rain risk up to #{rain}%."
      end

      nil
    end

    private

    def overlaps_period?(hour)
      local = hour.forecast_at.in_time_zone(@forecast.location.timezone)
      minute = (local.hour * 60) + local.min
      minute >= minutes(@period.fetch(:starts_at)) && minute < minutes(@period.fetch(:ends_at))
    end

    def hourly_payload
      weather_class = @hours.map(&:weather_class).max_by { |value| SEVERITY.fetch(value, 0) }
      {
        source: "hourly",
        weather_class:,
        condition_label: @hours.find { |hour| hour.weather_class == weather_class }&.condition_label,
        activity_context: worst_context,
        temperature_min_c: @hours.map(&:temperature_c).map(&:to_f).min.round(1),
        temperature_max_c: @hours.map(&:temperature_c).map(&:to_f).max.round(1),
        precipitation_probability: @hours.map(&:precipitation_probability).max,
        precipitation_mm: @hours.sum { |hour| hour.precipitation_mm.to_f }.round(1),
        wind_speed_kph: @hours.map(&:wind_speed_kph).map(&:to_f).max.round(1),
        daylight: @hours.all?(&:daylight)
      }
    end

    def daily_payload
      {
        source: "daily",
        weather_class: @forecast.weather_class,
        condition_label: @forecast.condition_label,
        activity_context: @forecast.activity_context,
        temperature_min_c: @forecast.temperature_min_c.to_f,
        temperature_max_c: @forecast.temperature_max_c.to_f,
        precipitation_probability: @forecast.precipitation_probability,
        precipitation_mm: @forecast.precipitation_mm.to_f,
        wind_speed_kph: @forecast.wind_speed_kph.to_f,
        daylight: true
      }
    end

    def worst_context
      return "caution" if @hours.any? { |hour| hour.activity_context == "caution" }
      return "indoor" if @hours.any? { |hour| hour.activity_context == "indoor" }
      return "flexible" if @hours.any? { |hour| hour.activity_context == "flexible" }

      "outdoor"
    end

    def minutes(value)
      hour, minute = value.split(":").map(&:to_i)
      (hour * 60) + minute
    end
  end
end
