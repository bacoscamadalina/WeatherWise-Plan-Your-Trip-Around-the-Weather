module Recommendations
  module Discovery
    class TmdbProvider < Provider
      ENDPOINT = "https://api.themoviedb.org/3/discover/movie"
      GENRES = {
        12 => "adventure", 14 => "fantasy", 16 => "animation", 18 => "drama",
        27 => "horror", 28 => "action", 35 => "comedy", 36 => "history",
        53 => "thriller", 80 => "crime", 99 => "documentary", 878 => "science-fiction",
        9648 => "mystery", 10_402 => "music", 10_749 => "romance",
        10_751 => "family", 10_752 => "war", 10_770 => "tv-movie", 37 => "western"
      }.freeze

      def initialize(
        client: ExternalApi::HttpClient.new,
        token: ENV["TMDB_BEARER_TOKEN"],
        default_language: ENV.fetch("MOVIE_LANGUAGE", "en-US"),
        catalog_pages: ENV.fetch("MOVIE_CATALOG_PAGES", 3)
      )
        @client = client
        @token = token
        @default_language = default_language
        @catalog_pages = catalog_pages.to_i.clamp(1, 5)
      end

      def name = "tmdb"

      def cache_scope(request:)
        Recommendation.where(provider: name)
          .where("metadata ->> 'language' = ?", requested_language(request))
      end

      def discover(request:)
        raise ExternalApi::Error, "TMDB_BEARER_TOKEN is not configured" if @token.blank?

        language = requested_language(request)
        headers = {
          "Authorization" => "Bearer #{@token}",
          "Accept" => "application/json"
        }
        (1..@catalog_pages).flat_map do |page|
          payload = @client.get_json(
            uri(request.location.country_code, tmdb_language(language), page:),
            headers:
          )
          Array(payload["results"]).first(20).filter_map { |movie| map(movie, language) }
        end.uniq(&:external_id)
      end

      private

      def requested_language(request)
        value = request.preferences[:language].to_s.downcase.split("-").first
        return value if %w[en ro].include?(value)

        @default_language.to_s.downcase.start_with?("ro") ? "ro" : "en"
      end

      def tmdb_language(language)
        language == "ro" ? "ro-RO" : "en-US"
      end

      def uri(country_code, language, page:)
        URI(ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            include_adult: false,
            include_video: false,
            language:,
            page:,
            region: country_code,
            sort_by: "popularity.desc",
            "vote_count.gte": 300
          )
        end
      end

      def map(movie, language)
        title = movie["title"].presence
        return unless title

        genres = Array(movie["genre_ids"]).filter_map { |id| GENRES[id] }
        CatalogItem.new(
          location: nil,
          recommendation_type: "movie",
          title:,
          summary: movie["overview"].presence || fallback_summary(language),
          venue_name: nil,
          indoor: true,
          provider: name,
          external_id: "#{language}-#{movie.fetch('id')}",
          url: "https://www.themoviedb.org/movie/#{movie.fetch('id')}?language=#{tmdb_language(language)}",
          genres:,
          tags: [ "movie", "live" ],
          weather_classes: weather_classes(genres),
          metadata: {
            poster_url: poster_url(movie["poster_path"]),
            rating: movie["vote_average"],
            release_date: movie["release_date"],
            language:,
            tmdb_id: movie.fetch("id")
          }.compact
        )
      end

      def fallback_summary(language)
        return "Un film popular ales pentru un plan confortabil în interior." if language == "ro"

        "A popular movie selected for an indoor plan."
      end

      def weather_classes(genres)
        return %w[rain storm fog] if (genres & %w[horror thriller mystery crime]).any?
        return %w[rain snow cloudy] if (genres & %w[family fantasy animation comedy]).any?

        %w[rain cloudy]
      end

      def poster_url(path)
        "https://image.tmdb.org/t/p/w500#{path}" if path.present?
      end
    end
  end
end
