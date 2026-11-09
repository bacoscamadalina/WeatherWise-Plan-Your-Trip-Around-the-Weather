module Forecasts
  class TrackAccess
    def call(location:, at: Time.current)
      location.with_lock do
        access = location.forecast_accesses.find_or_initialize_by(
          accessed_on: at.to_date
        )
        access.request_count = access.request_count.to_i + 1
        access.last_accessed_at = at
        access.save!
        access
      end
    end
  end
end
