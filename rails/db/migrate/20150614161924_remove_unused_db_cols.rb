class RemoveUnusedDbCols < ActiveRecord::Migration
  def change
    remove_column :locations, :area
    remove_column :locations, :raw_area
    remove_column :locations, :parents
  end
end
