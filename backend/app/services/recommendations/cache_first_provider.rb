module Recommendations
  class CacheFirstProvider < Provider
    def initialize(database: DatabaseProvider.new, refresh_job: RefreshLocationRecommendationsJob)
      @database = database
      @refresh_job = refresh_job
    end

    def suggestions(request:)
      enqueue_refresh(request)
      @database.suggestions(request:)
    end

    private

    def enqueue_refresh(request)
      @refresh_job.perform_later(
        location: request.location,
        forecast: request.forecast,
        type: request.preferences[:type],
        language: request.preferences[:language] || "en"
      )
    end
  end
end
