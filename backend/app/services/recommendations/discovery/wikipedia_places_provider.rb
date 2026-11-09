module Recommendations
  module Discovery
    class WikipediaPlacesProvider < Provider
      DEFAULT_RADIUS_METERS = 20_000
      PLACE_TERMS = %w[
        museum monastery church cathedral basilica synagogue mosque temple
        palace castle fortress theatre theater opera library gallery garden
        park zoo memorial monument tower square hall aquarium botanical
        muzeu manastire biserica catedrala sinagoga moschee templu palat castel
        cetate teatru opera biblioteca galerie gradina parc memorial monument turn piata
      ].freeze
      INDOOR_TERMS = %w[
        museum monastery church cathedral basilica synagogue mosque temple
        palace theatre theater opera library gallery hall aquarium
        muzeu manastire biserica catedrala sinagoga moschee templu palat teatru
        opera biblioteca galerie
      ].freeze

      def initialize(
        client: ExternalApi::HttpClient.new,
        radius_meters: ENV.fetch("ACTIVITY_RADIUS_METERS", DEFAULT_RADIUS_METERS).to_i,
        image_resolver: nil
      )
        @client = client
        @radius_meters = radius_meters.clamp(500, 20_000)
        @image_resolver = image_resolver || WikimediaImageResolver.new(client:)
      end

      def name = "wikipedia"

      def cache_scope(request:)
        Recommendation.where(provider: name, location: request.location)
          .where("metadata ->> 'language' = ?", requested_language(request))
      end

      def discover(request:)
        request_language = requested_language(request)
        content_language = request_language
        pages = eligible_pages(request.location, content_language)
        if pages.empty? && content_language != "en"
          content_language = "en"
          pages = eligible_pages(request.location, content_language)
        end
        pages.reject! { |page| same_place?(page["title"], request.location.name) }
        images = @image_resolver.resolve(image_elements(pages), language: content_language)

        pages.filter_map do |page|
          map(page, request.location, images[page_key(page)], request_language, content_language)
        end
          .sort_by { |item| item.metadata.fetch(:distance_km) }
          .first(20)
      end

      private

      def eligible_pages(location, language)
        pages = Array(@client.get_json(uri(location, language)).dig("query", "pages"))
        pages.reject { |page| same_place?(page["title"], location.name) }
          .select { |page| eligible_place?(page) }
      end

      def uri(location, language)
        URI("https://#{language}.wikipedia.org/w/api.php").tap do |uri|
          uri.query = URI.encode_www_form(
            action: "query",
            format: "json",
            formatversion: 2,
            generator: "geosearch",
            ggsprimary: "all",
            ggsnamespace: 0,
            ggsradius: @radius_meters,
            ggscoord: "#{location.latitude}|#{location.longitude}",
            ggslimit: 40,
            prop: "coordinates|pageimages|info",
            inprop: "url",
            piprop: "thumbnail|name",
            pithumbsize: 1_200,
            pilicense: "free",
            origin: "*"
          )
        end
      end

      def image_elements(pages)
        pages.filter_map do |page|
          next unless page["pageimage"].present?

          {
            "type" => "page",
            "id" => page.fetch("pageid"),
            "tags" => { "wikimedia_commons" => "File:#{page.fetch("pageimage")}" }
          }
        end
      end

      def map(page, location, image, request_language, content_language)
        coordinates = Array(page["coordinates"]).first
        return unless coordinates && image

        latitude = coordinates.fetch("lat").to_f
        longitude = coordinates.fetch("lon").to_f
        indoor = indoor_place?(page.fetch("title"))
        classification = classify_place(page.fetch("title"))
        CatalogItem.new(
          location:,
          recommendation_type: "activity",
          title: page.fetch("title"),
          summary: summary(location, content_language),
          venue_name: page.fetch("title"),
          indoor:,
          provider: name,
          external_id: "#{request_language}:#{location_cache_key(location)}:page/#{page.fetch("pageid")}",
          url: page["fullurl"],
          genres: [],
          tags: ([ "attraction" ] + classification.fetch(:tags) +
            [ indoor ? "indoor" : "outdoor", "live", "setting-unverified" ]).uniq,
          weather_classes: indoor ? %w[rain snow storm fog cloudy clear] : %w[clear cloudy],
          metadata: {
            latitude:,
            longitude:,
            distance_km: distance_km(location.latitude.to_f, location.longitude.to_f, latitude, longitude).round(1),
            image_url: image.url,
            image_attribution: image.attribution,
            image_source_url: image.source_url,
            activity_kind: classification.fetch(:activity_kind),
            activity_category: classification.fetch(:activity_category),
            language: request_language,
            content_language:
          }
        )
      end

      def same_place?(title, location_name)
        normalize(title) == normalize(location_name)
      end

      def eligible_place?(page)
        title = normalize(page["title"])
        filename = normalize(page["pageimage"])
        PLACE_TERMS.any? { |term| title.include?(term) } &&
          filename.exclude?("logo") && filename.exclude?(" map") && filename.exclude?("flag") &&
          filename.exclude?("coat of arms") && filename.exclude?("emblem")
      end

      def indoor_place?(title)
        normalized = normalize(title)
        INDOOR_TERMS.any? { |term| normalized.include?(term) }
      end

      def classify_place(title)
        normalized = normalize(title)
        return place_classification("culture", "museum", %w[culture museum]) if normalized.match?(/museum|muzeu|gallery|galerie/)
        return place_classification("nature", "park", %w[nature park]) if normalized.match?(/park|parc|garden|gradina|botanical/)
        return place_classification("entertainment", "zoo", %w[entertainment zoo]) if normalized.match?(/zoo|aquarium/)
        return place_classification("entertainment", "performance", %w[entertainment culture theatre]) if normalized.match?(/theatre|theater|teatru|opera/)
        if normalized.match?(/church|biserica|cathedral|catedrala|basilica|synagogue|sinagoga|mosque|moschee|temple|templu|monastery|manastire/)
          return place_classification("culture", "religious_heritage", %w[culture history heritage])
        end
        if normalized.match?(/palace|palat|castle|castel|fortress|cetate|memorial|monument|tower|turn/)
          return place_classification("culture", "heritage", %w[culture history heritage])
        end

        place_classification("culture", "landmark", %w[culture landmark])
      end

      def place_classification(activity_kind, activity_category, tags)
        { activity_kind:, activity_category:, tags: }
      end

      def summary(location, language)
        return "Un obiectiv remarcabil din apropiere de #{location.name}, cu o poveste locală documentată." if language == "ro"

        "A notable place near #{location.name} with a documented local story."
      end

      def requested_language(request)
        value = request.preferences[:language].to_s.downcase.split("-").first
        %w[en ro].include?(value) ? value : "en"
      end

      def normalize(value)
        value.to_s.tr("_", " ").unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip
      end

      def page_key(page)
        "page/#{page.fetch("pageid")}"
      end

      def location_cache_key(location)
        location.id || "#{location.latitude.to_f.round(4)},#{location.longitude.to_f.round(4)}"
      end

      def distance_km(latitude_1, longitude_1, latitude_2, longitude_2)
        radius = 6371.0
        lat_delta = (latitude_2 - latitude_1) * Math::PI / 180
        lon_delta = (longitude_2 - longitude_1) * Math::PI / 180
        a = Math.sin(lat_delta / 2)**2 +
          Math.cos(latitude_1 * Math::PI / 180) * Math.cos(latitude_2 * Math::PI / 180) * Math.sin(lon_delta / 2)**2
        radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      end
    end
  end
end
