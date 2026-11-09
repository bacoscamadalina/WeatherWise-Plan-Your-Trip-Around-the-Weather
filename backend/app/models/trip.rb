class Trip < ApplicationRecord
  PACES = %w[relaxed balanced active].freeze
  TRANSPORT_MODES = %w[walking public_transport car bicycle].freeze
  STATUSES = %w[draft planned archived].freeze
  BUDGETS = %w[value moderate flexible].freeze
  DIETARY_PREFERENCES = %w[vegetarian vegan gluten_free].freeze
  INTERESTS = %w[culture nature entertainment].freeze
  MAX_DAYS = 14

  belongs_to :user, optional: true
  belongs_to :location
  has_many :trip_days, -> { order(:date) }, dependent: :destroy, inverse_of: :trip

  validates :name, :starts_on, :ends_on, presence: true
  validates :party_size, numericality: { only_integer: true, in: 1..20 }
  validates :pace, inclusion: { in: PACES }
  validates :transport_mode, inclusion: { in: TRANSPORT_MODES }
  validates :status, inclusion: { in: STATUSES }
  validates :max_distance_km, numericality: { in: 1..50 }
  validate :valid_preferences
  validate :valid_date_range
  validate :valid_same_day_window

  before_validation :normalize_preferences

  def day_count
    return 0 unless starts_on && ends_on

    (ends_on - starts_on).to_i + 1
  end

  private

  def normalize_preferences
    values = preferences.is_a?(Hash) ? preferences.stringify_keys : {}
    self.preferences = {
      "budget" => values.fetch("budget", "flexible").to_s,
      "dietary" => Array(values["dietary"]).map(&:to_s).uniq,
      "interests" => Array(values["interests"]).map(&:to_s).uniq
    }
  end

  def valid_preferences
    return unless preferences.is_a?(Hash)

    errors.add(:preferences, "has an unsupported budget") unless preferences["budget"].in?(BUDGETS)
    if (Array(preferences["dietary"]) - DIETARY_PREFERENCES).any?
      errors.add(:preferences, "has unsupported dietary preferences")
    end
    if (Array(preferences["interests"]) - INTERESTS).any?
      errors.add(:preferences, "has unsupported interests")
    end
  end

  def valid_date_range
    return unless starts_on && ends_on

    errors.add(:ends_on, "must be on or after the start date") if ends_on < starts_on
    errors.add(:ends_on, "must be within #{MAX_DAYS} days of the start date") if day_count > MAX_DAYS
  end

  def valid_same_day_window
    return unless starts_on && ends_on && starts_on == ends_on
    return unless arrival_time && departure_time
    return if clock_minutes(arrival_time) < clock_minutes(departure_time)

    errors.add(:departure_time, "must be after the arrival time for a one-day trip")
  end

  def clock_minutes(value)
    (value.hour * 60) + value.min
  end
end
