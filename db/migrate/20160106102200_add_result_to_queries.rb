class AddResultToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :result, :string
  end
end
