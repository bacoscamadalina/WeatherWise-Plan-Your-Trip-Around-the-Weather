module Api
  module V1
    class LocationsController < BaseController
      def search
        query = params[:q].to_s.strip
        if query.length < 2
          return render json: { error: { code: "invalid_query", message: "q must contain at least 2 characters" } },
            status: :unprocessable_content
        end

        per_page = params.fetch(:per_page, params.fetch(:limit, 5)).to_i.clamp(1, 10)
        page = params.fetch(:page, 1).to_i.clamp(1, 100)
        language = requested_language
        results = Locations::Search.new.call(query:, page:, per_page:, language:)

        render json: {
          data: results.map { |location| location_json(location) },
          meta: {
            query:,
            language:,
            count: results.size,
            page: results.page,
            per_page: results.per_page,
            has_more: results.has_more,
            attribution: { label: "Location data by GeoNames via Open-Meteo", url: "https://open-meteo.com/" }
          }
        }
      end
    end
  end
end
