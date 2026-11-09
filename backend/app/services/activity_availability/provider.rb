module ActivityAvailability
  class Provider
    def check(recommendation:, forecast:, period:)
      raise NotImplementedError, "#{self.class} must implement #check"
    end

    def name
      raise NotImplementedError, "#{self.class} must implement #name"
    end
  end
end
