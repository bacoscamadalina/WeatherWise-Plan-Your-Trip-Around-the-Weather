module Showtimes
  Listing = Data.define(
    :id,
    :film_id,
    :film_title,
    :cinema_id,
    :cinema_name,
    :date,
    :format,
    :start_time,
    :end_time,
    :distance_km,
    :image_url
  )
end
