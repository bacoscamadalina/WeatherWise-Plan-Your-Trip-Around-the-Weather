module Recommendations
  module Discovery
    class ProviderFactory
      def self.activity(name = configured_activity_providers)
        activities(name).first
      end

      def self.activities(names = configured_activity_providers)
        names = names.to_s
        return auto_activity_providers if names == "auto"

        names.split(",").map { |name| build_activity_provider(name.strip) }.uniq(&:name)
      end

      def self.configured_activity_providers
        ENV["ACTIVITY_PROVIDERS"].presence || ENV.fetch("ACTIVITY_PROVIDER", default_activity_provider)
      end

      def self.auto_activity_providers
        [ WikipediaPlacesProvider.new, OverpassProvider.new ]
      end

      def self.build_activity_provider(name)
        case name
        when "database" then NullProvider.new
        when "overpass" then OverpassProvider.new
        when "wikipedia" then WikipediaPlacesProvider.new
        else raise ArgumentError, "Unsupported activity provider: #{name}"
        end
      end

      def self.default_activity_provider
        Rails.env.test? ? "database" : "auto"
      end

      def self.movie(name = ENV.fetch("MOVIE_PROVIDER", "auto"))
        case name
        when "database" then NullProvider.new
        when "tmdb" then TmdbProvider.new
        when "auto" then ENV["TMDB_BEARER_TOKEN"].present? ? TmdbProvider.new : NullProvider.new
        else raise ArgumentError, "Unsupported movie provider: #{name}"
        end
      end

      def self.event(name = configured_event_providers)
        events(name).first
      end

      def self.events(names = configured_event_providers)
        names = names.to_s
        return auto_event_providers if names == "auto"

        names.split(",").map { |name| build_event_provider(name.strip) }.uniq(&:name)
      end

      def self.configured_event_providers
        ENV["EVENT_PROVIDERS"].presence || ENV.fetch("EVENT_PROVIDER", "auto")
      end

      def self.auto_event_providers
        providers = []
        providers << TicketmasterProvider.new if ENV["TICKETMASTER_API_KEY"].present?
        providers << PredictHqProvider.new if ENV["PREDICTHQ_ACCESS_TOKEN"].present?
        providers.presence || [ NullProvider.new ]
      end

      def self.build_event_provider(name)
        case name
        when "database" then NullProvider.new
        when "ticketmaster" then TicketmasterProvider.new
        when "predicthq" then PredictHqProvider.new
        else raise ArgumentError, "Unsupported event provider: #{name}"
        end
      end
    end
  end
end
