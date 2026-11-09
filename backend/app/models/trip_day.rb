class TripDay < ApplicationRecord
  belongs_to :trip, inverse_of: :trip_days
  belongs_to :daily_forecast, optional: true
  has_many :itinerary_items, -> { order(:position) }, dependent: :destroy, inverse_of: :trip_day

  validates :date, presence: true, uniqueness: { scope: :trip_id }
  validate :date_inside_trip

  private

  def date_inside_trip
    return unless date && trip&.starts_on && trip&.ends_on
    return if date.between?(trip.starts_on, trip.ends_on)

    errors.add(:date, "must fall inside the trip")
  end
end
