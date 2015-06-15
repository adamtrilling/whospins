# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150614161924) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "postgis"

  create_table "authorizations", force: true do |t|
    t.integer "user_id"
    t.string  "provider"
    t.string  "uid"
    t.hstore  "info"
  end

  add_index "authorizations", ["info"], :name => "authorizations_info_index"
  add_index "authorizations", ["provider"], :name => "index_authorizations_on_provider"
  add_index "authorizations", ["uid"], :name => "index_authorizations_on_uid"
  add_index "authorizations", ["user_id"], :name => "index_authorizations_on_user_id"

  create_table "geonames", id: false, force: true do |t|
    t.integer "id",                            null: false
    t.string  "name",              limit: 200
    t.string  "ascii_name",        limit: 200
    t.text    "alt_names"
    t.float   "lat"
    t.float   "lng"
    t.string  "feature_class",     limit: 1
    t.string  "feature_code",      limit: 10
    t.string  "country",           limit: 2
    t.text    "cc2"
    t.string  "admin1",            limit: 20
    t.string  "admin2",            limit: 80
    t.string  "admin3",            limit: 20
    t.string  "admin4",            limit: 20
    t.integer "population",        limit: 8
    t.integer "elevation"
    t.integer "dem"
    t.string  "timezone",          limit: 40
    t.date    "modification_date"
  end

  add_index "geonames", ["admin1"], :name => "admin1_idx"
  add_index "geonames", ["admin2"], :name => "admin2_idx"
  add_index "geonames", ["admin3"], :name => "admin3_idx"
  add_index "geonames", ["admin4"], :name => "admin4_idx"
  add_index "geonames", ["country"], :name => "country_idx"
  add_index "geonames", ["feature_class"], :name => "feature_class_idx"
  add_index "geonames", ["feature_code"], :name => "feature_code_idx"
  add_index "geonames", ["name"], :name => "name_idx"

  create_table "hierarchy", id: false, force: true do |t|
    t.integer "parent_id"
    t.integer "child_id"
    t.string  "category",  limit: 40
  end

  add_index "hierarchy", ["child_id"], :name => "child_id_idx"
  add_index "hierarchy", ["parent_id"], :name => "parent_id_idx"

  create_table "locations", force: true do |t|
    t.string  "name"
    t.string  "category"
    t.hstore  "props"
    t.boolean "always_show", default: false
    t.integer "num_users"
    t.float   "percentile",  default: 0.0
    t.text    "geojson"
    t.integer "geonames_id"
    t.integer "parent_id"
    t.integer "adm_level"
  end

  add_index "locations", ["adm_level"], :name => "index_locations_on_adm_level"
  add_index "locations", ["always_show"], :name => "index_locations_on_always_show"
  add_index "locations", ["category"], :name => "index_locations_on_category"
  add_index "locations", ["geonames_id"], :name => "index_locations_on_geonames_id"
  add_index "locations", ["name"], :name => "index_locations_on_name"
  add_index "locations", ["num_users"], :name => "index_locations_on_num_users"
  add_index "locations", ["parent_id"], :name => "index_locations_on_parent_id"
  add_index "locations", ["percentile"], :name => "index_locations_on_percentile"
  add_index "locations", ["props"], :name => "locations_props_index"

  create_table "locations_users", id: false, force: true do |t|
    t.integer "location_id"
    t.integer "user_id"
    t.integer "old_location_id"
  end

  add_index "locations_users", ["location_id", "user_id"], :name => "index_locations_users_on_location_id_and_user_id", :unique => true
  add_index "locations_users", ["location_id"], :name => "index_locations_users_on_location_id"
  add_index "locations_users", ["old_location_id"], :name => "index_locations_users_on_old_location_id"
  add_index "locations_users", ["user_id"], :name => "index_locations_users_on_user_id"

  create_table "users", force: true do |t|
    t.hstore   "location_names"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
