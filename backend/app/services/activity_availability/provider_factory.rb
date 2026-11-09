module ActivityAvailability
  class ProviderFactory
    def self.build(name = ENV.fetch("ACTIVITY_AVAILABILITY_PROVIDER", "unavailable"))
      case name
      when "unavailable", "database" then UnavailableProvider.new
      when "google_places"
        ENV["GOOGLE_PLACES_API_KEY"].present? ? GooglePlacesProvider.new : UnavailableProvider.new
      else raise ArgumentError, "Unsupported activity availability provider: #{name}"
      end
    end
  end
end
