module LocationImages
  class ProviderFactory
    def self.build(name = ENV.fetch("LOCATION_IMAGE_PROVIDER", default_provider))
      case name
      when "none" then NullProvider.new
      when "wikimedia" then WikimediaProvider.new
      else
        raise ArgumentError, "Unsupported location image provider: #{name}"
      end
    end

    def self.default_provider
      Rails.env.test? ? "none" : "wikimedia"
    end
  end
end
