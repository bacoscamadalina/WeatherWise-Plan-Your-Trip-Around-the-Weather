module Recommendations
  class RefreshingProvider < Provider
    REFRESH_LOCKS = {}
    REFRESH_LOCKS_GUARD = Mutex.new

    def initialize(
      database: DatabaseProvider.new,
      activity_provider: nil,
      activity_providers: nil,
      movie_provider: Discovery::ProviderFactory.movie,
      event_provider: nil,
      event_providers: nil
    )
      @database = database
      @activity_providers = activity_providers ||
        (activity_provider ? [ activity_provider ] : Discovery::ProviderFactory.activities)
      @movie_provider = movie_provider
      @event_providers = event_providers || (event_provider ? [ event_provider ] : Discovery::ProviderFactory.events)
    end

    def suggestions(request:)
      requested_type = request.preferences[:type]
      @activity_providers.each { |provider| refresh(provider, request) } unless requested_type.in?(%w[event movie])
      refresh(@movie_provider, request) unless requested_type.in?(%w[activity event])
      @event_providers.each { |provider| refresh(provider, request) } unless requested_type.in?(%w[activity movie])
      @database.suggestions(request:)
    end

    private

    def refresh(source, request)
      return if source.name == "database" || fresh?(source, request)

      lock = refresh_lock(source, request)
      return unless lock.try_lock

      begin
        return if fresh?(source, request)

        items = source.discover(request:)
        external_ids = items.map(&:external_id)
        source.cache_scope(request:).where.not(external_id: external_ids).update_all(active: false, updated_at: Time.current)
        items.each { |item| persist(item) }
      ensure
        lock.unlock
      end
    rescue ExternalApi::Error => error
      Rails.logger.warn("#{source.name} discovery unavailable: #{error.message}")
    end

    def refresh_lock(source, request)
      scope_key = source.cache_scope(request:).to_sql
      REFRESH_LOCKS_GUARD.synchronize do
        REFRESH_LOCKS[[ source.name, scope_key ]] ||= Mutex.new
      end
    end

    def fresh?(source, request)
      ttl = ENV.fetch("RECOMMENDATION_CACHE_TTL_MINUTES", 360).to_i.minutes
      latest_refresh = source.cache_scope(request:).maximum(:updated_at)
      latest_refresh.present? && latest_refresh >= ttl.ago
    end

    def persist(item)
      recommendation = Recommendation.find_or_initialize_by(
        provider: item.provider,
        external_id: item.external_id
      )
      recommendation.update!(item.to_h.except(:provider, :external_id).merge(active: true))
    end
  end
end
