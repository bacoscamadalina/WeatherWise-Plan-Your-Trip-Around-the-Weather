module Locations
  SearchPage = Data.define(:locations, :page, :per_page, :has_more) do
    include Enumerable

    def each(&block) = locations.each(&block)
    def first = locations.first
    def size = locations.size
  end

  class Search
    MAX_PROVIDER_RESULTS = 100

    def initialize(provider: Geocoding::ProviderFactory.build)
      @provider = provider
    end

    def call(query:, page: 1, per_page: 5, language: "en")
      return SearchPage.new(locations: [], page: 1, per_page:, has_more: false) if query.blank?

      per_page = per_page.to_i.clamp(1, 10)
      page = page.to_i.clamp(1, max_page(per_page))
      offset = (page - 1) * per_page
      provider_limit = [ offset + per_page + 1, MAX_PROVIDER_RESULTS ].min
      results = rank(@provider.search(query:, limit: provider_limit, language:), query)
      page_results = results.slice(offset, per_page) || []

      locations = page_results.map { |result| persist(result, language:) }
      SearchPage.new(
        locations:,
        page:,
        per_page:,
        has_more: results.size > offset + per_page
      )
    end

    private

    def persist(result, language:)
      Location.find_or_initialize_by(provider: result.provider, external_id: result.external_id).tap do |location|
        previous_names = [ location.name, *location.aliases ].compact_blank
        location.assign_attributes(
          result.to_h.except(:provider, :external_id, :aliases).merge(
            aliases: (previous_names + result.aliases).uniq - [ result.name ],
            localized_names: location.localized_names.merge(language => result.name)
          )
        )
        location.save!
      end
    end

    def rank(results, query)
      normalized_query = normalize(query.split(",", 2).first)
      results.sort_by do |result|
        names = [ result.name, *result.aliases ].map { |value| normalize(value) }
        match_rank = if names.include?(normalized_query)
          0
        elsif names.any? { |name| name.start_with?(normalized_query) }
          1
        else
          2
        end
        capital_rank = result.feature_code == "PPLC" ? 0 : 1
        [ match_rank, capital_rank, -result.population.to_i, result.name ]
      end
    end

    def max_page(per_page)
      (MAX_PROVIDER_RESULTS.to_f / per_page).ceil
    end

    def normalize(value)
      value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase.strip
    end
  end
end
