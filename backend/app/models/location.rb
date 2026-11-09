class Location < ApplicationRecord
  has_many :daily_forecasts, dependent: :destroy
  has_many :forecast_accesses, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :trips, dependent: :destroy

  validates :name, :country_code, :latitude, :longitude, :provider, :external_id, presence: true
  validates :latitude, numericality: { in: -90..90 }
  validates :longitude, numericality: { in: -180..180 }
  validates :country_code, length: { is: 2 }
  validates :population, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :hero_image_url, :hero_image_source_url, allow_blank: true,
    format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]), message: "must be an HTTPS URL" }

  def display_name
    [ name, admin_area, country_name.presence || country_code ].compact_blank.join(", ")
  end
end
