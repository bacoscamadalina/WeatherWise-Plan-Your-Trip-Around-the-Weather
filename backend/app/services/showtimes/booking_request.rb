module Showtimes
  BookingRequest = Data.define(:location, :date, :film_id, :cinema_id, :time)
end
