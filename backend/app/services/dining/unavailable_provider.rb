module Dining
  class UnavailableProvider < Provider
    def search(location:, meal:, radius_km:, language:, preferences: {})
      []
    end
  end
end
