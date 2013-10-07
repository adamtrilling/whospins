class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.integer :parent_id
      t.string :name
      t.string :category
      t.hstore :props # for finding parent/child relationships
      t.boolean :always_show, :default => false
      t.integer :num_users # cache to speed up percent_rank()
      t.multi_polygon :raw_area, :srid => 4326
      t.multi_polygon :area, :srid => 4326
    end

    add_index :locations, :name
    add_index :locations, :parent_id
    add_index :locations, :category
    execute "CREATE INDEX locations_props_index ON locations USING gin(props)"
    add_index :locations, :always_show
    add_index :locations, :num_users
    add_index :locations, :raw_area, :spatial => true
    add_index :locations, :area, :spatial => true

    # habtm table locations <=> users
    create_table :locations_users, :id => false do |t|
      t.references :location
      t.references :user
    end

    add_index :locations_users, :location_id
    add_index :locations_users, :user_id
  end
end
