class AddHeroImageryToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :hero_image_url, :string
    add_column :locations, :image_attribution, :string
    add_column :locations, :hero_image_source_url, :string
    add_column :locations, :hero_image_provider, :string
    add_column :locations, :hero_image_fetched_at, :datetime

    add_index :locations, :hero_image_fetched_at
  end
end
