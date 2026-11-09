module LocationImages
  class Fetch
    DEFAULT_TTL = 30.days

    def initialize(provider: ProviderFactory.build, ttl: cache_ttl)
      @provider = provider
      @ttl = ttl
    end

    def call(location:, language: "en", refresh: false)
      return location if !refresh && fresh?(location)

      result = @provider.fetch(location:, language:)
      attributes = { hero_image_fetched_at: Time.current }
      if result
        attributes.merge!(
          hero_image_url: result.image_url,
          image_attribution: result.attribution,
          hero_image_source_url: result.source_url,
          hero_image_provider: result.provider
        )
      end
      location.update!(attributes)
      location
    rescue ExternalApi::Error => error
      Rails.logger.warn("Location image provider failure for location #{location.id}: #{error.message}")
      location
    end

    private

    def fresh?(location)
      location.hero_image_fetched_at.present? && location.hero_image_fetched_at >= @ttl.ago
    end

    def self.cache_ttl
      ENV.fetch("LOCATION_IMAGE_CACHE_TTL_DAYS", 30).to_i.clamp(1, 365).days
    end

    def cache_ttl
      self.class.cache_ttl
    end
  end
end
