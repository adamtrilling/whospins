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

ActiveRecord::Schema.define(version: 20130302024307) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "locations", force: true do |t|
    t.integer "parent_id"
    t.string  "name"
    t.string  "category"
    t.string  "uid"
    t.integer "num_users",                                               default: 0
    t.spatial "raw_area",  limit: {:srid=>4326, :type=>"multi_polygon"}
    t.spatial "area",      limit: {:srid=>4326, :type=>"multi_polygon"}
  end

  add_index "locations", ["area"], :name => "index_locations_on_area", :spatial => true
  add_index "locations", ["category"], :name => "index_locations_on_category"
  add_index "locations", ["name"], :name => "index_locations_on_name"
  add_index "locations", ["num_users"], :name => "index_locations_on_num_users"
  add_index "locations", ["parent_id"], :name => "index_locations_on_parent_id"
  add_index "locations", ["raw_area"], :name => "index_locations_on_raw_area", :spatial => true
  add_index "locations", ["uid"], :name => "index_locations_on_uid"

  create_table "users", force: true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "location_id"
  end

  add_index "users", ["location_id"], :name => "index_users_on_location_id"

end
