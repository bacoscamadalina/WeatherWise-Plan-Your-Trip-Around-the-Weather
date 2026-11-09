module Api
  module V1
    class HourlyForecastsController < BaseController
      def show
        forecast = DailyForecast.includes(:location).find(params[:forecast_id])
        hours = HourlyForecasts::Fetch.new.call(
          daily_forecast: forecast,
          refresh: ActiveModel::Type::Boolean.new.cast(params[:refresh])
        )

        render json: {
          data: {
            forecast_id: forecast.id,
            date: forecast.forecast_date.iso8601,
            timezone: forecast.location.timezone,
            hours: hours.map { |hour| hourly_forecast_json(hour, forecast.location) }
          },
          meta: {
            count: hours.size,
            generated_at: Time.current.iso8601,
            provider: hours.first&.provider,
            attribution: attribution_for(hours.first&.provider)
          }
        }
      end

      private

      def hourly_forecast_json(hour, location)
        local_time = hour.forecast_at.in_time_zone(location.timezone)
        {
          time: local_time.iso8601,
          local_time: local_time.strftime("%Y-%m-%dT%H:%M:%S"),
          condition: {
            code: hour.condition_code,
            label: hour.condition_label,
            weather_class: hour.weather_class
          },
          activity_context: hour.activity_context,
          temperature_c: hour.temperature_c.to_f,
          precipitation: {
            probability: hour.precipitation_probability,
            amount_mm: hour.precipitation_mm.to_f
          },
          wind_speed_kph: hour.wind_speed_kph.to_f,
          daylight: hour.daylight
        }
      end

      def attribution_for(provider)
        return unless provider == "open_meteo"

        { label: "Weather data by Open-Meteo", url: "https://open-meteo.com/" }
      end
    end
  end
end
