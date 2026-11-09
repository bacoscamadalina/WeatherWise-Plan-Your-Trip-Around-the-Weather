module Weather
  class Provider
    # Return one provider-native hash per day. Normalizer owns conversion to our schema.
    def daily_forecast(location:, days: 14)
      raise NotImplementedError, "#{self.class} must implement #daily_forecast"
    end

    # Return one provider-native hash per local hour for the requested date.
    def hourly_forecast(location:, date:)
      raise NotImplementedError, "#{self.class} must implement #hourly_forecast"
    end

    def hourly_forecast_range(location:, start_date:, end_date:)
      (start_date..end_date).flat_map do |date|
        hourly_forecast(location:, date:)
      end
    end

    def name
      self.class.name.demodulize.delete_suffix("Provider").underscore
    end
  end
end
