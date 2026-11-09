module Api
  module V1
    class ForecastsController < BaseController
      def index
        location = Location.find(params[:location_id])
        days = params.fetch(:days, 14).to_i.clamp(1, 14)
        forecasts = Forecasts::Fetch.new.call(location:, days:, refresh: ActiveModel::Type::Boolean.new.cast(params[:refresh]))
        Forecasts::TrackAccess.new.call(location:)
        LocationImages::Fetch.new.call(location:, language: requested_language)

        render json: {
          data: {
            location: location_json(location),
            forecasts: forecasts.map { |forecast| forecast_json(forecast) }
          },
          meta: {
            days: forecasts.size,
            generated_at: Time.current.iso8601,
            forecast_updated_at: forecasts.filter_map(&:fetched_at).min&.iso8601,
            provider: forecasts.first&.provider,
            attribution: attribution_for(forecasts.first&.provider)
          }
        }
      end

      private

      def attribution_for(provider)
        return unless provider == "open_meteo"

        { label: "Weather data by Open-Meteo", url: "https://open-meteo.com/" }
      end
    end
  end
end
