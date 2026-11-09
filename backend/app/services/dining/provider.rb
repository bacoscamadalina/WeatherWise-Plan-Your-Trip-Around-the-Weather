module Dining
  class Provider
    def search(location:, meal:, radius_km:, language:, preferences: {})
      raise NotImplementedError
    end

    def live? = false
  end
end
