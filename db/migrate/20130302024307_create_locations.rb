class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer :parent_id
      t.string :name
      t.string :category
      t.hstore :props # for finding parent/child relationships
      t.integer :num_users, :default => 0
      t.boolean :always_show, :default => false
      t.multi_polygon :raw_area, :srid => 4326
      t.multi_polygon :area, :srid => 4326
    end

    add_index :locations, :name
    add_index :locations, :parent_id
    add_index :locations, :category
    execute "CREATE INDEX locations_uids_index ON locations USING gin(props)"
    add_index :locations, :num_users
    add_index :locations, :always_show
    add_index :locations, :raw_area, :spatial => true
    add_index :locations, :area, :spatial => true

    add_column :users, :location_id, :integer
    add_index :users, :location_id
  end
end
