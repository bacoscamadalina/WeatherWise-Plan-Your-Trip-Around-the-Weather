module ActivityAvailability
  Result = Data.define(
    :status,
    :label,
    :detail,
    :period,
    :provider,
    :checked_at,
    :place_name,
    :place_url
  )
end
