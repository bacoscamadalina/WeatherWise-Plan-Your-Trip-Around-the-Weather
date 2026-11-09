require "cgi"

module LocationImages
  class WikimediaProvider < Provider
    ARTICLE_ENDPOINT = "https://en.wikipedia.org/w/api.php"
    COMMONS_ENDPOINT = "https://commons.wikimedia.org/w/api.php"
    SEARCH_RADIUS_METERS = 10_000
    THUMBNAIL_WIDTH = 1_600

    def initialize(client: ExternalApi::HttpClient.new)
      @client = client
    end

    def fetch(location:, language: "en")
      payload = @client.get_json(article_uri(location))
      page = matching_page(payload, location.name)
      page ||= matching_page(@client.get_json(exact_title_uri(location)), location.name)
      return unless page&.dig("thumbnail", "source") && page["pageimage"]

      metadata = image_metadata(page.fetch("pageimage"), language)
      return unless metadata

      Result.new(
        image_url: page.dig("thumbnail", "source"),
        attribution: attribution(metadata),
        source_url: metadata["descriptionurl"] || page["fullurl"],
        provider: "wikimedia"
      )
    end

    private

    def article_uri(location)
      URI(ARTICLE_ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(
          action: "query",
          format: "json",
          formatversion: 2,
          generator: "geosearch",
          ggsprimary: "all",
          ggsnamespace: 0,
          ggsradius: SEARCH_RADIUS_METERS,
          ggscoord: "#{location.latitude}|#{location.longitude}",
          ggslimit: 20,
          prop: "pageimages|info",
          inprop: "url",
          piprop: "thumbnail|name",
          pithumbsize: THUMBNAIL_WIDTH,
          pilicense: "free",
          redirects: 1,
          origin: "*"
        )
      end
    end

    def exact_title_uri(location)
      candidates = [
        location.name,
        [ location.name, location.admin_area ].compact_blank.join(", "),
        [ location.name, location.country_name ].compact_blank.join(", "),
        ("#{location.name} (#{location.country_name})" if location.country_name.present?)
      ].compact_blank.uniq

      URI(ARTICLE_ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(
          action: "query",
          format: "json",
          formatversion: 2,
          titles: candidates.join("|"),
          prop: "pageimages|info",
          inprop: "url",
          piprop: "thumbnail|name",
          pithumbsize: THUMBNAIL_WIDTH,
          pilicense: "free",
          redirects: 1,
          origin: "*"
        )
      end
    end

    def matching_page(payload, location_name)
      normalized_name = normalize(location_name)
      Array(payload.dig("query", "pages"))
        .select { |page| page["ns"].to_i.zero? && page["pageimage"].present? }
        .min_by do |page|
          title = normalize(page["title"])
          if title == normalized_name
            0
          elsif title.start_with?("#{normalized_name} (") || title.start_with?("#{normalized_name},")
            1
          else
            100
          end
        end
        .then do |page|
          next unless page

          title = normalize(page["title"])
          page if title == normalized_name || title.start_with?("#{normalized_name} (") || title.start_with?("#{normalized_name},")
        end
    end

    def image_metadata(filename, language)
      payload = @client.get_json(metadata_uri(filename, language))
      Array(payload.dig("query", "pages")).first&.dig("imageinfo", 0)
    end

    def metadata_uri(filename, language)
      URI(COMMONS_ENDPOINT).tap do |uri|
        uri.query = URI.encode_www_form(
          action: "query",
          format: "json",
          formatversion: 2,
          prop: "imageinfo",
          titles: "File:#{filename}",
          iiprop: "url|extmetadata",
          iiextmetadatalanguage: safe_language(language),
          iiextmetadatafilter: "Artist|Credit|LicenseShortName",
          origin: "*"
        )
      end
    end

    def attribution(metadata)
      fields = metadata.fetch("extmetadata", {})
      artist = clean(fields.dig("Artist", "value") || fields.dig("Credit", "value"))
      license = clean(fields.dig("LicenseShortName", "value"))
      [ artist, license, "Wikimedia Commons" ].compact_blank.uniq.join(" · ")
    end

    def clean(value)
      CGI.unescapeHTML(value.to_s.gsub(/<[^>]*>/, " ").squish).presence
    end

    def safe_language(language)
      value = language.to_s.downcase.split("-").first
      value.match?(/\A[a-z]{2,3}\z/) ? value : "en"
    end

    def normalize(value)
      value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip
    end
  end
end
