module Weather
  class ProviderFactory
    def self.build(name = ENV.fetch("WEATHER_PROVIDER", default_provider))
      case name
      when "mock" then MockProvider.new
      when "open_meteo" then OpenMeteoProvider.new
      else
        raise ArgumentError, "Unsupported weather provider: #{name}"
      end
    end

    def self.default_provider
      Rails.env.test? ? "mock" : "open_meteo"
    end
  end
end
