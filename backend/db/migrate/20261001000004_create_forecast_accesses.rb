class CreateForecastAccesses < ActiveRecord::Migration[8.0]
  def change
    create_table :forecast_accesses do |t|
      t.references :location, null: false, foreign_key: true
      t.date :accessed_on, null: false
      t.integer :request_count, null: false, default: 0
      t.datetime :last_accessed_at, null: false
      t.timestamps
    end

    add_index :forecast_accesses, %i[location_id accessed_on], unique: true
    add_index :forecast_accesses, :last_accessed_at
  end
end
