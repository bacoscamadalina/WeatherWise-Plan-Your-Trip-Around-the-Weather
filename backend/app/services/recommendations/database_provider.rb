module Recommendations
  class DatabaseProvider < Provider
    def suggestions(request:)
      language = request.preferences[:language] || "en"
      items = Recommendation.active.available_in(request.location).select do |item|
        !item.provider.in?(%w[wikipedia openstreetmap tmdb]) || item.metadata["language"] == language
      end

      return items unless items.any? { |item| item.provider == "tmdb" && item.recommendation_type == "movie" }

      items.reject { |item| item.provider == "seed" && item.recommendation_type == "movie" }
    end
  end
end
