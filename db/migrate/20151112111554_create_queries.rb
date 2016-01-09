class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.text :description
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
    # add_foreign_key :queries, :users
    add_index :queries, [:user_id, :created_at]
  end
end
