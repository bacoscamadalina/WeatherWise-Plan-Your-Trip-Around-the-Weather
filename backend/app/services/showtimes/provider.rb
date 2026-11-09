module Showtimes
  class Provider
    def for_date(request:)
      raise NotImplementedError, "#{self.class} must implement #for_date"
    end

    def name
      raise NotImplementedError, "#{self.class} must implement #name"
    end

    def booking_link(request:)
      raise NotImplementedError, "#{self.class} must implement #booking_link"
    end
  end
end
