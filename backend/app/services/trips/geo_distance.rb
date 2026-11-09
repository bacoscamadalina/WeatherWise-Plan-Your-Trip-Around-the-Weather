module Trips
  module GeoDistance
    EARTH_RADIUS_KM = 6_371.0

    module_function

    def km(first, second)
      return unless coordinates?(first) && coordinates?(second)

      latitude_delta = radians(second.fetch(:latitude).to_f - first.fetch(:latitude).to_f)
      longitude_delta = radians(second.fetch(:longitude).to_f - first.fetch(:longitude).to_f)
      first_latitude = radians(first.fetch(:latitude).to_f)
      second_latitude = radians(second.fetch(:latitude).to_f)
      haversine = Math.sin(latitude_delta / 2)**2 +
        Math.cos(first_latitude) * Math.cos(second_latitude) * Math.sin(longitude_delta / 2)**2
      (EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine))).round(1)
    end

    def coordinates?(point)
      point&.dig(:latitude).present? && point&.dig(:longitude).present?
    end

    def radians(value) = value * Math::PI / 180
  end
end
