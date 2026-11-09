class ItineraryItem < ApplicationRecord
  SLOTS = %w[breakfast morning lunch afternoon dinner evening].freeze
  KINDS = %w[meal activity event movie free_time].freeze
  STATUSES = %w[suggested confirmed replaced unavailable].freeze

  belongs_to :trip_day, inverse_of: :itinerary_items
  belongs_to :recommendation, optional: true

  validates :slot, inclusion: { in: SLOTS }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :title, presence: true
  validates :rating, numericality: { in: 0..5 }, allow_nil: true
  validates :rating_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :url, :image_url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
end
