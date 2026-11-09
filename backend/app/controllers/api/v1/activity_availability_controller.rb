module Api
  module V1
    class ActivityAvailabilityController < BaseController
      def show
        forecast = DailyForecast.includes(:location).find(params[:forecast_id])
        recommendation = Recommendation.active
          .available_in(forecast.location)
          .find_by!(id: params[:recommendation_id], recommendation_type: "activity")
        result = ActivityAvailability::ProviderFactory.build.check(
          recommendation:,
          forecast:,
          period: period
        )

        render json: {
          data: result.to_h,
          meta: {
            live: result.provider.present?,
            attribution: attribution_for(result.provider)
          }
        }
      end

      private

      def period
        value = params.fetch(:period, "afternoon")
        return value if Recommendations::Timing::PERIODS.include?(value)

        raise ActionController::BadRequest, "period must be morning, afternoon, or evening"
      end

      def attribution_for(provider)
        return unless provider == "google_places"

        {
          label: "Google Maps",
          url: "https://maps.google.com"
        }
      end
    end
  end
end
