class AddQueryfileToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :queryfile, :string
  end
end
