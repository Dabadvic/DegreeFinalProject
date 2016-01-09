class AddAlgorithmToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :algorithm, :string
  end
end
