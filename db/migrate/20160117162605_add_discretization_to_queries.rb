class AddDiscretizationToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :discretization, :string
  end
end
