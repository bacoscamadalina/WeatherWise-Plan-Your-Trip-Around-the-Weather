class ForecastAccess < ApplicationRecord
  belongs_to :location

  validates :accessed_on, :last_accessed_at, presence: true
  validates :request_count, numericality: { only_integer: true, greater_than: 0 }
end
