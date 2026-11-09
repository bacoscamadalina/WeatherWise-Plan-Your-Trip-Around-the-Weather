require "cgi"

module Recommendations
  module Discovery
    class WikimediaImageResolver
      Image = Data.define(:url, :attribution, :source_url)
      WIKIDATA_ENDPOINT = "https://www.wikidata.org/w/api.php"
      COMMONS_ENDPOINT = "https://commons.wikimedia.org/w/api.php"
      THUMBNAIL_WIDTH = 1_200

      def initialize(client: ExternalApi::HttpClient.new)
        @client = client
      end

      def resolve(elements, language: "en")
        filenames = wikidata_filenames(elements)
        filenames.merge!(direct_filenames(elements))
        return {} if filenames.empty?

        images = commons_images(filenames.values.uniq, language)
        filenames.filter_map do |element_key, filename|
          image = images[normalize_filename(filename)]
          [ element_key, image ] if image
        end.to_h
      end

      private

      def direct_filenames(elements)
        elements.filter_map do |element|
          value = element.dig("tags", "wikimedia_commons").to_s
          next unless value.start_with?("File:")

          [ element_key(element), value.delete_prefix("File:") ]
        end.to_h
      end

      def wikidata_filenames(elements)
        keyed_ids = elements.filter_map do |element|
          id = element.dig("tags", "wikidata").to_s
          [ element_key(element), id ] if id.match?(/\AQ\d+\z/)
        end.to_h
        return {} if keyed_ids.empty?

        payload = @client.get_json(wikidata_uri(keyed_ids.values.uniq))
        entities = payload.fetch("entities", {})
        keyed_ids.filter_map do |element_key, id|
          filename = entities.dig(id, "claims", "P18", 0, "mainsnak", "datavalue", "value")
          [ element_key, filename ] if filename.present?
        end.to_h
      end

      def commons_images(filenames, language)
        payload = @client.get_json(commons_uri(filenames, language))
        Array(payload.dig("query", "pages")).filter_map do |page|
          info = page.dig("imageinfo", 0)
          next unless info

          filename = page.fetch("title").delete_prefix("File:")
          image_url = info["thumburl"] || info["url"]
          next unless image_url.to_s.start_with?("https://")

          [
            normalize_filename(filename),
            Image.new(
              url: image_url,
              attribution: attribution(info.fetch("extmetadata", {})),
              source_url: info["descriptionurl"]
            )
          ]
        end.to_h
      end

      def wikidata_uri(ids)
        URI(WIKIDATA_ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            action: "wbgetentities",
            format: "json",
            ids: ids.join("|"),
            props: "claims",
            origin: "*"
          )
        end
      end

      def commons_uri(filenames, language)
        URI(COMMONS_ENDPOINT).tap do |uri|
          uri.query = URI.encode_www_form(
            action: "query",
            format: "json",
            formatversion: 2,
            prop: "imageinfo",
            titles: filenames.map { |filename| "File:#{filename}" }.join("|"),
            iiprop: "url|extmetadata",
            iiurlwidth: THUMBNAIL_WIDTH,
            iiextmetadatalanguage: safe_language(language),
            iiextmetadatafilter: "Artist|Credit|LicenseShortName",
            origin: "*"
          )
        end
      end

      def attribution(metadata)
        artist = clean(metadata.dig("Artist", "value") || metadata.dig("Credit", "value"))
        license = clean(metadata.dig("LicenseShortName", "value"))
        [ artist, license, "Wikimedia Commons" ].compact_blank.uniq.join(" · ")
      end

      def clean(value)
        CGI.unescapeHTML(value.to_s.gsub(/<[^>]*>/, " ").squish).presence
      end

      def element_key(element)
        "#{element.fetch("type")}/#{element.fetch("id")}"
      end

      def normalize_filename(filename)
        CGI.unescape(filename.to_s.tr("_", " ")).unicode_normalize(:nfkc).downcase.strip
      end

      def safe_language(language)
        value = language.to_s.downcase.split("-").first
        value.match?(/\A[a-z]{2,3}\z/) ? value : "en"
      end
    end
  end
end
