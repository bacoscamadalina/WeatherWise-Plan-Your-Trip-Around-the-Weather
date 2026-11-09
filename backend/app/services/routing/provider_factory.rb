module Routing
  module ProviderFactory
    module_function

    def build
      provider = ENV.fetch("ROUTING_PROVIDER", "auto")
      return GoogleRoutesProvider.new if provider == "google_routes"
      return GoogleRoutesProvider.new if provider == "auto" && ENV["GOOGLE_ROUTES_API_KEY"].present?

      UnavailableProvider.new
    end
  end
end
