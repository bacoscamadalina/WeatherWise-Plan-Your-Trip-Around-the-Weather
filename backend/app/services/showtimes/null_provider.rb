module Showtimes
  class NullProvider < Provider
    def name = "database"
    def for_date(request:) = []
    def booking_link(request:) = nil
  end
end
