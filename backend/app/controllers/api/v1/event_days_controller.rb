module Api
  module V1
    class EventDaysController < BaseController
      def show
        location = Location.find(params[:id])
        start_date, end_date = date_range
        forecasts = location.daily_forecasts.where(forecast_date: start_date..end_date).order(:forecast_date).to_a
        days = Recommendations::EventCalendar.new.call(location:, forecasts:, language: requested_language)

        render json: {
          data: days.map do |day|
            {
              date: day.date.iso8601,
              count: day.count,
              preview: {
                title: day.preview_title,
                venue_name: day.preview_venue,
                image_url: day.preview_image_url
              }.compact,
              providers: day.providers
            }
          end,
          meta: { start_date: start_date.iso8601, end_date: end_date.iso8601, count: days.size }
        }
      end

      private

      def date_range
        start_date = Date.iso8601(params.fetch(:start_date))
        end_date = Date.iso8601(params.fetch(:end_date))
        raise ActionController::BadRequest, "date range must contain 1 to 14 days" unless (0..13).cover?((end_date - start_date).to_i)

        [ start_date, end_date ]
      rescue Date::Error, KeyError
        raise ActionController::BadRequest, "start_date and end_date must use YYYY-MM-DD"
      end
    end
  end
end
