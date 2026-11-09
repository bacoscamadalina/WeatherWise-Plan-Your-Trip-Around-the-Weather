module Api
  module V1
    class ShowtimesController < BaseController
      def index
        forecast = DailyForecast.includes(:location).find(params[:forecast_id])
        provider = Showtimes::ProviderFactory.build
        listings = provider.for_date(
          request: Showtimes::Request.new(
            location: forecast.location,
            date: forecast.forecast_date,
            limit: params.fetch(:limit, 5).to_i.clamp(1, 10)
          )
        )

        render json: {
          data: {
            forecast: forecast_json(forecast),
            showtimes: listings.map { |listing| listing_json(listing) }
          },
          meta: {
            count: listings.size,
            provider: provider.name,
            attribution: attribution_for(provider.name),
            live: provider.name != "database"
          }
        }
      end

      def booking_link
        forecast = DailyForecast.includes(:location).find(params[:forecast_id])
        provider = Showtimes::ProviderFactory.build
        url = provider.booking_link(
          request: Showtimes::BookingRequest.new(
            location: forecast.location,
            date: forecast.forecast_date,
            film_id: numeric_parameter!(:film_id),
            cinema_id: numeric_parameter!(:cinema_id),
            time: time_parameter!
          )
        )
        unless url
          return render json: {
            error: {
              code: "booking_link_unavailable",
              message: "A cinema booking link is not available for this showtime"
            }
          }, status: :not_found
        end

        render json: { data: { url:, provider: provider.name } }
      end

      private

      def listing_json(listing)
        {
          id: listing.id,
          film_id: listing.film_id,
          film_title: listing.film_title,
          cinema_id: listing.cinema_id,
          cinema_name: listing.cinema_name,
          date: listing.date.iso8601,
          format: listing.format,
          start_time: listing.start_time,
          end_time: listing.end_time,
          distance_km: listing.distance_km,
          image_url: listing.image_url
        }
      end

      def attribution_for(provider)
        return unless provider == "movieglu"

        { label: "Cinema and showtime data by MovieGlu", url: "https://www.movieglu.com" }
      end

      def numeric_parameter!(name)
        value = params[name].to_s
        return value if value.match?(/\A\d+\z/)

        raise ActionController::BadRequest, "#{name} must be numeric"
      end

      def time_parameter!
        value = params[:time].to_s
        return value if value.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)

        raise ActionController::BadRequest, "time must use 24-hour HH:MM format"
      end
    end
  end
end
