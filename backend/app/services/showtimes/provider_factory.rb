module Showtimes
  class ProviderFactory
    def self.build(name = ENV.fetch("SHOWTIME_PROVIDER", "database"))
      case name
      when "database" then NullProvider.new
      when "movieglu" then MovieGluProvider.new
      else raise ArgumentError, "Unsupported showtime provider: #{name}"
      end
    end
  end
end
