class LocationsMultipleInheritance < ActiveRecord::Migration
  def change
    add_column :locations, :parents, :hstore
    execute "CREATE INDEX locations_parents_index ON locations USING gin(parents)"

    # move all of the location parents into the new hash
    execute "UPDATE locations SET parents = hstore(parent_id::text, 'in') WHERE parent_id IS NOT NULL"

    # drop the old parent column
    remove_index :locations, :parent_id
    remove_column :locations, :parent_id

    # index to do case-insensitive lookups
    execute "CREATE INDEX location_names_lowercase ON locations ((lower(name)))"
  end
end
