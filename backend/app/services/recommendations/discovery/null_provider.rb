module Recommendations
  module Discovery
    class NullProvider < Provider
      def discover(request:) = []
      def name = "database"
      def cache_scope(request:) = Recommendation.none
    end
  end
end
