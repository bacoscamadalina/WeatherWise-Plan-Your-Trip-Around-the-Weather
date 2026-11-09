module Recommendations
  module Discovery
    class OverpassProvider < Provider
      ENDPOINT = "https://maps.mail.ru/osm/tools/overpass/api/interpreter"
      FALLBACK_ENDPOINT = "https://overpass.private.coffee/api/interpreter"
      SECONDARY_FALLBACK_ENDPOINT = "https://overpass-api.de/api/interpreter"
      DEFAULT_RADIUS_METERS = 50_000
      INDOOR_AMENITIES = %w[cinema theatre arts_centre library planetarium].freeze
      INDOOR_TOURISM = %w[museum gallery].freeze
      OUTDOOR_LEISURE = %w[park garden nature_reserve].freeze
      OUTDOOR_TOURISM = %w[viewpoint attraction zoo picnic_site].freeze
      MOUNTAIN_TOURISM = %w[alpine_hut wilderness_hut trail_riding_station].freeze
      HIKING_ROUTES = %w[hiking foot].freeze
      ROMANIAN_CATEGORIES = {
        "cinema" => "cinematograf", "theatre" => "teatru", "arts_centre" => "centru cultural",
        "library" => "bibliotecă", "planetarium" => "planetariu", "museum" => "muzeu",
        "gallery" => "galerie", "park" => "parc", "garden" => "grădină",
        "nature_reserve" => "rezervație naturală", "viewpoint" => "punct panoramic",
        "attraction" => "atracție locală", "zoo" => "grădină zoologică",
        "picnic_site" => "zonă de picnic", "alpine_hut" => "cabană alpină",
        "wilderness_hut" => "refugiu montan", "trail_riding_station" => "centru ecvestru"
      }.freeze

      def initialize(
        client: nil,
        endpoint: ENV.fetch("OVERPASS_API_URL", ENDPOINT),
        endpoints: nil,
        radius_meters: ENV.fetch("ACTIVITY_RADIUS_METERS", DEFAULT_RADIUS_METERS).to_i,
        image_resolver: nil
      )
        @client = client || ExternalApi::HttpClient.new(read_timeout: 18, max_attempts: 1)
        @endpoints = endpoints || configured_endpoints(endpoint)
        @radius_meters = radius_meters.clamp(500, 50_000)
        @image_resolver = image_resolver || WikimediaImageResolver.new(client: @client)
      end

      def name = "openstreetmap"

      def cache_scope(request:)
        Recommendation.where(provider: name, location: request.location)
          .where("metadata ->> 'language' = ?", requested_language(request))
      end

      def discover(request:)
        elements = fetch_payloads(request.location)
          .flat_map { |payload| Array(payload["elements"]) }
          .uniq { |element| element_key(element) }
        images = @image_resolver.resolve(elements)
        elements.filter_map { |element| map(element, request, images[element_key(element)]) }
          .uniq { |item| normalized_identity(item) }
          .sort_by { |item| item.metadata.fetch(:distance_km) }
          .first(120)
      end

      private

      def uri(overpass_query, endpoint = @endpoints.first)
        URI(endpoint).tap do |uri|
          uri.query = URI.encode_www_form(data: overpass_query)
        end
      end

      def fetch_payloads(location)
        payloads = []
        errors = []
        [ routes_query(location), places_query(location) ].each do |overpass_query|
          payloads << fetch_payload(overpass_query)
        rescue ExternalApi::Error => error
          errors << error
          Rails.logger.warn("openstreetmap partial discovery unavailable: #{error.message}")
        end
        raise errors.last if payloads.empty? && errors.any?

        payloads
      end

      def fetch_payload(overpass_query)
        last_error = nil
        @endpoints.each do |endpoint|
          return @client.get_json(uri(overpass_query, endpoint))
        rescue ExternalApi::Error => error
          last_error = error
        end
        raise last_error if last_error

        { "elements" => [] }
      end

      def configured_endpoints(primary)
        configured = ENV["OVERPASS_API_URLS"].to_s.split(",").map(&:strip).reject(&:blank?)
        (configured.presence || [ primary, FALLBACK_ENDPOINT, SECONDARY_FALLBACK_ENDPOINT ]).uniq
      end

      def places_query(location)
        bounds = bounding_box(location)
        <<~OVERPASS.squish
          [out:json][timeout:20];
          (
            nwr#{bounds}["amenity"~"^(#{INDOOR_AMENITIES.join("|")})$"];
            nwr#{bounds}["tourism"~"^(#{(INDOOR_TOURISM + OUTDOOR_TOURISM + MOUNTAIN_TOURISM).join("|")})$"];
            nwr#{bounds}["leisure"~"^(#{OUTDOOR_LEISURE.join("|")})$"];
            node#{bounds}["natural"="peak"];
          );
          out center tags 160;
        OVERPASS
      end

      def routes_query(location)
        bounds = bounding_box(location)
        <<~OVERPASS.squish
          [out:json][timeout:20];
          relation#{bounds}["type"="route"]["route"~"^(#{HIKING_ROUTES.join("|")})$"];
          out tags center 120;
        OVERPASS
      end

      def map(element, request, image)
        location = request.location
        tags = element.fetch("tags", {})
        title = localized_name(tags, request.preferences[:language])
        return unless title

        latitude, longitude = coordinates_for(element, tags, location)
        return unless latitude && longitude
        distance = distance_km(
          location.latitude.to_f, location.longitude.to_f, latitude.to_f, longitude.to_f
        )
        return if distance > (@radius_meters / 1_000.0)

        classification = classify(tags)
        category = classification.fetch(:category)
        indoor = classification.fetch(:indoor)
        CatalogItem.new(
          location:,
          recommendation_type: "activity",
          title:,
          summary: summary(title, category, indoor, tags, request.preferences[:language]),
          venue_name: title,
          indoor:,
          provider: name,
          external_id: "#{requested_language(request)}:#{location_cache_key(location)}:#{element.fetch("type")}/#{element.fetch("id")}",
          url: "https://www.openstreetmap.org/#{element.fetch("type")}/#{element.fetch("id")}",
          genres: [],
          tags: (classification.fetch(:tags) + [ indoor ? "indoor" : "outdoor", "live" ]).uniq,
          weather_classes: indoor ? %w[rain snow storm fog cloudy] : %w[clear cloudy],
          metadata: {
            latitude: latitude.to_f,
            longitude: longitude.to_f,
            distance_km: distance.round(1),
            opening_hours: tags["opening_hours"],
            activity_kind: classification.fetch(:activity_kind),
            activity_category: category,
            language: requested_language(request),
            weather_sensitivity: classification[:weather_sensitivity],
            elevation_m: numeric_tag(tags["ele"]),
            prominence_m: numeric_tag(tags["prominence"]),
            route_distance_km: route_distance(tags["distance"]),
            route_start: first_tag(tags, "from", "start", "start_point"),
            route_end: first_tag(tags, "to", "destination", "end", "end_point"),
            duration_minutes: duration_minutes(first_tag(tags, "duration", "estimated_duration")),
            ascent_m: numeric_tag(first_tag(tags, "ascent", "elevation:gain")),
            descent_m: numeric_tag(first_tag(tags, "descent", "elevation:loss")),
            roundtrip: boolean_tag(tags["roundtrip"]),
            difficulty: difficulty(tags),
            trail_visibility: tags["trail_visibility"],
            surface: tags["surface"],
            network: tags["network"],
            route_ref: tags["ref"],
            trail_marker: tags["osmc:symbol"],
            route_operator: tags["operator"],
            official_url: first_tag(tags, "website", "contact:website"),
            image_url: image&.url,
            image_attribution: image&.attribution,
            image_source_url: image&.source_url
          }.compact
        )
      end

      def element_key(element)
        "#{element.fetch("type")}/#{element.fetch("id")}"
      end

      def coordinates_for(element, tags, location)
        if HIKING_ROUTES.include?(tags["route"])
          closest = route_geometry_points(element).min_by do |point|
            distance_km(
              location.latitude.to_f, location.longitude.to_f,
              point.fetch(:latitude), point.fetch(:longitude)
            )
          end
          return [ closest.fetch(:latitude), closest.fetch(:longitude) ] if closest
        end

        [ element["lat"] || element.dig("center", "lat"), element["lon"] || element.dig("center", "lon") ]
      end

      def route_geometry_points(element)
        geometries = [ element["geometry"], *Array(element["members"]).map { |member| member["geometry"] } ]
        points = geometries.compact.flatten.filter_map do |point|
          latitude = point["lat"]
          longitude = point["lon"]
          { latitude: latitude.to_f, longitude: longitude.to_f } if latitude && longitude
        end
        points.concat(Array(element["members"]).filter_map do |member|
          latitude = member["lat"]
          longitude = member["lon"]
          { latitude: latitude.to_f, longitude: longitude.to_f } if latitude && longitude
        end)
        points
      end

      def classify(tags)
        if INDOOR_AMENITIES.include?(tags["amenity"])
          return classification(tags.fetch("amenity"), true, "entertainment")
        end
        if INDOOR_TOURISM.include?(tags["tourism"])
          return classification(tags.fetch("tourism"), true, "culture")
        end
        if tags["natural"] == "peak"
          return classification("peak", false, "nature", %w[hiking summit peak mountain], "dry_daylight")
        end
        if HIKING_ROUTES.include?(tags["route"])
          route_tag = tags["route"] == "hiking" ? "hiking" : "walking"
          sensitivity = tags["route"] == "hiking" ? "dry_daylight" : "outdoor_daylight"
          return classification("trail", false, "nature", [ route_tag, "trail", "route", "nature" ], sensitivity)
        end
        if MOUNTAIN_TOURISM.include?(tags["tourism"])
          return classification(tags.fetch("tourism"), false, "nature", %w[hiking mountain shelter], "dry_daylight")
        end
        if OUTDOOR_LEISURE.include?(tags["leisure"])
          return classification(tags.fetch("leisure"), false, "nature", [ "nature", tags.fetch("leisure") ], "outdoor_daylight")
        end

        category = tags.fetch("tourism", "attraction")
        activity_kind = category == "zoo" ? "entertainment" : "nature"
        classification(category, false, activity_kind, [ category, "nature" ], "outdoor_daylight")
      end

      def classification(category, indoor, activity_kind, tags = [ category ], weather_sensitivity = nil)
        { category:, indoor:, activity_kind:, tags:, weather_sensitivity: }
      end

      def summary(title, category, indoor, tags, language)
        return romanian_summary(title, category, indoor, tags) if language.to_s.start_with?("ro")

        return "A mapped summit at #{elevation_label(tags)}, suitable only when the forecast supports a dry daylight hike." if category == "peak" && tags["ele"].present?
        return "A mapped summit suitable only when the forecast supports a dry daylight hike." if category == "peak"
        return "A mapped hiking route near the selected place. Check official trail conditions and equipment requirements before leaving." if category == "trail"

        label = category.tr("_", " ")
        indoor ? "A nearby #{label} for a weather-proof local plan." : "A nearby #{label} to enjoy when conditions are comfortable."
      end

      def romanian_summary(_title, category, indoor, tags)
        return "Un vârf cartografiat la #{elevation_label(tags)}, recomandat numai când prognoza permite o drumeție uscată, în lumină naturală." if category == "peak" && tags["ele"].present?
        return "Un vârf cartografiat, recomandat numai când prognoza permite o drumeție uscată, în lumină naturală." if category == "peak"
        return "Un traseu de drumeție cartografiat în apropiere. Verifică starea oficială a traseului și echipamentul necesar înainte de plecare." if category == "trail"

        label = ROMANIAN_CATEGORIES.fetch(category, category.tr("_", " "))
        if indoor
          "Un loc de tip #{label} din apropiere, potrivit pentru un plan la adăpost."
        else
          "Un obiectiv de tip #{label} din apropiere, potrivit când condițiile sunt confortabile."
        end
      end

      def localized_name(tags, language)
        localized = tags["name:#{language.to_s.downcase.split("-").first}"]
        localized.presence || tags["name"].presence || tags["name:en"].presence
      end

      def requested_language(request)
        value = request.preferences[:language].to_s.downcase.split("-").first
        %w[en ro].include?(value) ? value : "en"
      end

      def elevation_label(tags)
        "#{numeric_tag(tags["ele"]) || tags["ele"]} m"
      end

      def numeric_tag(value)
        return if value.blank?

        normalized = value.to_s.downcase.tr(",", ".")
        number = Float(normalized[/[-+]?\d+(?:\.\d+)?/], exception: false)
        return unless number

        number *= 1_000 if normalized.match?(/\bkm\b/)
        number *= 0.3048 if normalized.match?(/\b(?:ft|feet)\b/)
        number.round
      end

      def route_distance(value)
        return if value.blank?

        normalized = value.to_s.downcase.tr(",", ".")
        number = Float(normalized[/\d+(?:\.\d+)?/], exception: false)
        return unless number

        kilometers = if normalized.match?(/\b(?:mi|mile|miles)\b/)
          number * 1.60934
        elsif normalized.match?(/\b(?:m|meter|meters|metre|metres)\b/) && !normalized.match?(/\bkm\b/)
          number / 1_000.0
        else
          number
        end
        kilometers.round(1)
      end

      def duration_minutes(value)
        return if value.blank?

        normalized = value.to_s.strip.upcase
        return if normalized.include?("-")

        if (match = normalized.match(/\APT(?:(\d+)H)?(?:(\d+)M)?\z/))
          hours = match[1].to_i
          minutes = match[2].to_i
          return hours * 60 + minutes if hours.positive? || minutes.positive?
        end

        if (match = normalized.match(/\A(?:(\d+(?:\.\d+)?)\s*H(?:OURS?)?)?(?:\s*(\d+)\s*M(?:IN(?:UTES?)?)?)?\z/))
          hours = match[1].to_f
          minutes = match[2].to_i
          total = (hours * 60).round + minutes
          return total if total.positive?
        end

        if (match = normalized.match(/\A(\d+)\s*(?:M|MIN|MINS|MINUTES)\z/))
          return match[1].to_i
        end

        parts = normalized.split(":")
        return Integer(parts.first, exception: false) if parts.one?
        return unless parts.length.in?([ 2, 3 ]) && parts.all? { |part| part.match?(/\A\d+\z/) }

        hours, minutes, seconds = parts.map(&:to_i)
        if parts.length == 2
          hours * 60 + minutes
        else
          (hours * 60 + minutes + seconds / 60.0).round
        end
      end

      def boolean_tag(value)
        return true if value == "yes"

        false if value == "no"
      end

      def difficulty(tags)
        tags["sac_scale"].presence
      end

      def first_tag(tags, *keys)
        keys.lazy.map { |key| tags[key].presence }.find(&:present?)
      end

      def location_cache_key(location)
        location.id || "#{location.latitude.to_f.round(4)},#{location.longitude.to_f.round(4)}"
      end

      def normalized_identity(item)
        [
          item.metadata[:activity_kind],
          item.title.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.squish
        ]
      end

      def bounding_box(location)
        latitude = location.latitude.to_f
        longitude = location.longitude.to_f
        latitude_delta = @radius_meters / 111_320.0
        longitude_delta = @radius_meters / (111_320.0 * Math.cos(latitude * Math::PI / 180).abs.clamp(0.01, 1.0))
        format(
          "(%.5f,%.5f,%.5f,%.5f)",
          latitude - latitude_delta,
          longitude - longitude_delta,
          latitude + latitude_delta,
          longitude + longitude_delta
        )
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
