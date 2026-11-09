class Recommendation < ApplicationRecord
  TYPES = %w[activity event movie].freeze

  belongs_to :location, optional: true
  has_many :itinerary_items, dependent: :nullify

  validates :recommendation_type, :title, :summary, :provider, :external_id, presence: true
  validates :recommendation_type, inclusion: { in: TYPES }
  validates :external_id, uniqueness: { scope: :provider }
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true

  scope :active, -> { where(active: true) }
  scope :available_in, ->(location) { where(location_id: [ nil, location.id ]) }
end
