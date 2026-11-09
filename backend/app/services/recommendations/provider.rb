module Recommendations
  class Provider
    def suggestions(request:)
      raise NotImplementedError, "#{self.class} must implement #suggestions"
    end
  end
end
