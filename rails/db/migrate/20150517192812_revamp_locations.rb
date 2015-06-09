class RevampLocations < ActiveRecord::Migration
  def change
    add_column :locations, :geojson, :text
    add_column :locations, :geonames_id, :integer
    add_index :locations, :geonames_id
    add_column :locations, :parent_id, :integer
    add_index :locations, :parent_id
    add_column :locations, :adm_level, :integer
    add_index :locations, :adm_level

    add_column :locations_users, :old_location_id, :integer
    add_index :locations_users, :old_location_id
  end
end
