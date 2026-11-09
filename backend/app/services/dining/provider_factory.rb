module Dining
  module ProviderFactory
    module_function

    def build
      provider = ENV.fetch("DINING_PROVIDER", "auto")
      return GooglePlacesProvider.new if provider == "google_places"
      return GooglePlacesProvider.new if provider == "auto" && ENV["GOOGLE_PLACES_API_KEY"].present?

      UnavailableProvider.new
    end
  end
end
