module Geocoding
  Result = Data.define(
    :name, :country_code, :admin_area, :latitude, :longitude,
    :timezone, :provider, :external_id, :country_name, :feature_code,
    :population, :aliases
  )

  class Provider
    def search(query:, limit: 5, language: nil)
      raise NotImplementedError, "#{self.class} must implement #search"
    end
  end
end
