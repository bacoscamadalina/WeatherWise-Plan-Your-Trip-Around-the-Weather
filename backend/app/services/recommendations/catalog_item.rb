module Recommendations
  CatalogItem = Data.define(
    :location, :recommendation_type, :title, :summary, :venue_name,
    :indoor, :provider, :external_id, :url, :genres, :tags,
    :weather_classes, :metadata
  )
end
