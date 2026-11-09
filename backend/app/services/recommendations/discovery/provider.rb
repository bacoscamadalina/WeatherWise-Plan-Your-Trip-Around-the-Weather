module Recommendations
  module Discovery
    class Provider
      def discover(request:)
        raise NotImplementedError, "#{self.class} must implement #discover"
      end

      def name
        raise NotImplementedError, "#{self.class} must implement #name"
      end

      def cache_scope(request:)
        raise NotImplementedError, "#{self.class} must implement #cache_scope"
      end
    end
  end
end
