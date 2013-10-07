class CachePercentRanks < ActiveRecord::Migration
  def change
    add_column :locations, :percentile, :float, :default => 0
    add_index :locations, :percentile

    User.set_location_numbers!
  end
end
