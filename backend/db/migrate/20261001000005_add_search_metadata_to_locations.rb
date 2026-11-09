class AddSearchMetadataToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :country_name, :string
    add_column :locations, :feature_code, :string
    add_column :locations, :population, :bigint
    add_column :locations, :aliases, :string, array: true, null: false, default: []
    add_column :locations, :localized_names, :jsonb, null: false, default: {}

    add_index :locations, :population
    add_index :locations, :aliases, using: :gin
    add_index :locations, :localized_names, using: :gin
  end
end
