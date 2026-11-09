module Routing
  class Provider
    def live? = false

    def route(origin:, destination:, transport_mode:, departure_at: nil, arrival_at: nil, language: "en")
      raise NotImplementedError
    end
  end
end
