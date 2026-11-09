class AddArrivalAndDepartureTimesToTrips < ActiveRecord::Migration[8.1]
  def change
    add_column :trips, :arrival_time, :time
    add_column :trips, :departure_time, :time
  end
end
