class AddAuthentication < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_digest, :string, null: false

    create_table :access_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :name, null: false, default: "default"
      t.datetime :last_used_at
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :access_tokens, :token_digest, unique: true
    add_index :access_tokens, :expires_at
  end
end
