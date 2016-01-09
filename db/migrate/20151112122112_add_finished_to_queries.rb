class AddFinishedToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :status, :integer
    add_column :queries, :finished_at, :datetime
  end
end
