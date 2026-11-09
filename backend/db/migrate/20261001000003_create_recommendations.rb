class CreateRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendations do |t|
      t.references :location, null: true, foreign_key: true
      t.string :recommendation_type, null: false
      t.string :title, null: false
      t.text :summary, null: false
      t.string :venue_name
      t.boolean :indoor, null: false
      t.string :provider, null: false
      t.string :external_id, null: false
      t.string :url
      t.string :genres, array: true, null: false, default: []
      t.string :tags, array: true, null: false, default: []
      t.string :weather_classes, array: true, null: false, default: []
      t.jsonb :metadata, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :recommendations, %i[provider external_id], unique: true
    add_index :recommendations, :recommendation_type
    add_index :recommendations, :genres, using: :gin
    add_index :recommendations, :weather_classes, using: :gin
  end
end
