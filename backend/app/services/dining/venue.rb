module Dining
  Venue = Data.define(
    :external_id, :name, :address, :latitude, :longitude, :rating,
    :rating_count, :price_level, :types, :url, :provider, :distance_km
  )
end
