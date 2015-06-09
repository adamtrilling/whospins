class Geoname < ActiveRecord::Base
end

def load_geonames_countries
  # world
  Location.find_or_create_by(id: 0).update_attributes(
    name: 'World',
    adm_level: 0,
    always_show: true
  )
  
  # countries
  File.open("#{DATA_DIR}/countryInfo.txt").each do |record|
    next if record[0] == '#'

    fields = geonames_split(record)
    next unless fields[16].to_i > 0
    puts "loading country #{fields[4]} (id #{fields[16]})"
    
    # update existing countries
    location = Location.where(["props -> 'iso_a2' = ? OR props -> 'iso' = ?", fields[0], fields[0]]).first
    if (location)
      location.update_attributes(geonames_id: fields[16].to_i)
    else
      location = Location.create(geonames_id: fields[16].to_i)
    end

    location.props ||= Hash.new
    location.update_attributes(
      name: fields[4],
      adm_level: 1,
      always_show: true,
      props: location.props.merge({
        'iso': fields[0],
        'iso3': fields[1],
        'iso-numeric': fields[2],
        'fips': fields[3] 
      }),
      parent_id: 0
    )
  end
end

def copy_geonames_data
  print "copying geonames data into database..."
  Location.connection.execute("drop table if exists geonames;")
  Location.connection.execute("create table geonames (
 id integer primary key,
 name varchar(200),
 ascii_name varchar(200),
 alt_names text,
 lat double precision,
 lng double precision,
 feature_class char(1),
 feature_code varchar(10),
 country char(2),
 cc2 text,
 admin1 varchar(20),
 admin2 varchar(80),
 admin3 varchar(20),
 admin4 varchar(20),
 population bigint,
 elevation integer,
 dem integer,
 timezone varchar(40),
 modification_date date
);")
    
  Location.connection.execute("COPY geonames FROM '#{DATA_DIR}/allCountries_admonly.txt' WITH NULL '';")

  ['name', 'feature_class', 'feature_code', 'country',
   'admin1', 'admin2', 'admin3', 'admin4'].each do |col|
    Location.connection.execute("create index #{col}_idx on geonames (#{col});")
  end
  puts "done"
end

def copy_hierarchy_data
  print "copying hierarchy into database..."
  Location.connection.execute("drop table if exists hierarchy;")
  Location.connection.execute("create table hierarchy (
 parent_id integer,
 child_id integer,
 category varchar(40)
);")

  Location.connection.execute("COPY hierarchy FROM '#{DATA_DIR}/hierarchy.txt' WITH NULL '';")

  ['parent_id', 'child_id'].each do |col|
    Location.connection.execute("create index #{col}_idx on hierarchy (#{col});")
  end
  puts "done"
end

def copy_geonames
  copy_geonames_data
  copy_hierarchy_data
end

def clear_city_data
  puts "cleaning locations_users"
  Location.connection.execute("DELETE FROM locations_users WHERE location_id IN (SELECT id FROM locations WHERE category = 'city')")
  puts "cleaning locations"
  Location.connection.execute("DELETE FROM locations WHERE category = 'city'")
end

def clear_non_us_data
  id_list = Geoname.where("country != 'US'").pluck(:id).join(',')
  Location.connection.execute("DELETE FROM hierarchy WHERE child_id IN (#{id_list});")
  Location.connection.execute("DELETE FROM geonames WHERE id IN (#{id_list});")
end

def load_geonames_divisions
  (1..4).each do |level|
    admin_sym = :"admin#{level}"
    puts "level #{level}"

    Location.where(adm_level: level).each do |parent_location|
      puts "#{parent_location.name}"
      # find geonames records
      Geoname.find_by_sql(["SELECT geonames.* FROM geonames JOIN hierarchy on hierarchy.child_id = geonames.id WHERE hierarchy.parent_id = ?", parent_location.geonames_id]).each do |geoname|
        # find the existing location
        puts "\tgeoname record #{geoname.name} (id #{geoname.id})"
        
        location = Location.find_by(geonames_id: geoname.id)
        unless (location.present?)
          location = Location.where(["exist(parents, ?) AND (props -> 'fips' = ? OR props -> 'postal' = ?)", parent_location.id.to_s, geoname.send(admin_sym), geoname.send(admin_sym)]).first
        end
        unless(location.present?)
          location = Location.create(geonames_id: geoname.id)
        end
        
        location.props ||= Hash.new
        location.update_attributes(
          name: geoname.name,
          adm_level: level + 1,
          props: location.props.merge({
            fips: geoname.send(admin_sym)
          }),
          geonames_id: geoname.id,
          parent_id: parent_location.id
        )
      end 
    end
  end
end

def geonames_split(record)
 record.force_encoding('ISO-8859-1').encode('UTF-8').split("\t")
end

namespace :maps do
  desc "load geonames data"
  task :load_geonames => :environment do
    load_geonames_countries
    copy_geonames
    clear_city_data
    load_geonames_divisions
  end

  task :load_geonames_us_only => :environment do
    load_geonames_countries
    copy_geonames
    clear_city_data
    clear_non_us_data
    load_geonames_divisions
  end

  task :copy_geonames => :environment do
    copy_geonames
  end

  task :clear_city_data => :environment do
    clear_city_data
  end

  task :clear_non_us_data => :environment do
    clear_non_us_data
  end

  task :load_geonames_divisions => :environment do
    load_geonames_divisions
  end
end