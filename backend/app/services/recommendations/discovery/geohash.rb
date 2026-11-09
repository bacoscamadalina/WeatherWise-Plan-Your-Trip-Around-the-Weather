module Recommendations
  module Discovery
    class Geohash
      ALPHABET = "0123456789bcdefghjkmnpqrstuvwxyz".freeze

      def self.encode(latitude, longitude, precision: 9)
        latitude_range = [ -90.0, 90.0 ]
        longitude_range = [ -180.0, 180.0 ]
        bits = []
        use_longitude = true

        until bits.length == precision * 5
          range = use_longitude ? longitude_range : latitude_range
          value = use_longitude ? longitude.to_f : latitude.to_f
          midpoint = range.sum / 2.0
          bits << (value >= midpoint ? 1 : 0)
          value >= midpoint ? range[0] = midpoint : range[1] = midpoint
          use_longitude = !use_longitude
        end

        bits.each_slice(5).map do |slice|
          ALPHABET[slice.join.to_i(2)]
        end.join
      end
    end
  end
end
