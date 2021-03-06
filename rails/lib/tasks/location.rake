require 'fileutils'

DATA_DIR = Rails.root.join('lib', 'data', 'location')
DB_SRID = 4326

def process_shapefile(attrs)
  cat = attrs['category']
  puts "Downloading shapefile #{attrs['url']}"
  unless (File.directory?(File.join(DATA_DIR, cat)))
    Dir.mkdir(File.join(DATA_DIR, cat))
  end

  unless (File.file?(File.join(DATA_DIR, cat, attrs['shapefile'])))
    curl_cmd = "curl -L -o #{DATA_DIR}/#{cat}/#{attrs['zipfile']} #{attrs['url']}"
    unzip_cmd = "unzip -d #{DATA_DIR}/#{cat}/ #{DATA_DIR}/#{cat}/#{attrs['zipfile']}"
    system curl_cmd
    system unzip_cmd
  end

  RGeo::Shapefile::Reader.open("#{DATA_DIR}/#{cat}/#{attrs['shapefile']}") do |file|
    puts "#{cat} file contains #{file.num_records} records."

    i = 1
    file.each do |record|
      print "(#{i} of #{file.num_records}) #{record["name"]}#{record["NAME"]}..."

      if (attrs.has_key?('parent_uid')) 
        parent = Location.where(:uid => record[attrs['parent_uid']]).first
      end

      locations = attrs['processor'].call(cat, record)
      puts "done"

      unless (locations.nil?)
        locations.each do |loc|

          if (attrs['geom_field'])
            loc.connection.update_sql("UPDATE locations SET #{attrs['geom_field']} = ST_Transform(ST_GeomFromText('#{record.geometry.as_text}', #{attrs['srid']}), #{DB_SRID}) WHERE id = #{loc.id}")
          else
            loc.connection.update_sql("UPDATE locations SET raw_area = ST_Transform(ST_GeomFromText('#{record.geometry.as_text}', #{attrs['srid']}), #{DB_SRID}) WHERE id = #{loc.id}")

            if (attrs['tolerance'])
              # transform to Web Mercator before simplifying, because simplifying 
              # lat/lon geometries causes weird things to happen.  like the state 
              # of Michigan disappearing.
              loc.connection.update_sql("UPDATE locations SET area = ST_Transform(st_multi(ST_SimplifyPreserveTopology(ST_Transform(raw_area, 900913), #{attrs['tolerance']})), #{DB_SRID}) WHERE id = #{loc.id}")
            else
              loc.connection.update_sql("UPDATE locations SET area = raw_area WHERE id = #{loc.id}")
            end
          end
        end
      end
      i += 1
    end
  end
end

namespace :location do
  desc "Remove existing location data"
  task :destroy => :environment do
    puts "Removing existing data"
    Location.destroy_all
    FileUtils.rm_rf(File.join(Whospins::Application.config.action_controller.page_cache_directory, 'tiles'))
  end

  desc "Load data from shapefiles, creating or updating the Locations table"
  task :load_north_america => :environment do

    FileUtils.mkdir_p DATA_DIR
    puts "Loading data"

    # this is weird and abuses metaprogramming a bit.  but it saves a lot of code 
    # repetition.  the processor needs to return either the locations it built for 
    # the current record, or nil if there is a failure or an intentional skip.  if
    # nil is returned, the area isn't added to the database.
    [ 
      {
        'category' => 'country',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries_lakes.zip',
        'zipfile' => 'ne_50m_admin_0_countries_lakes.zip',
        'shapefile' => 'ne_50m_admin_0_countries_lakes.shp',
        'srid' => '4326',
        'geom_field' => 'raw_area',
        'processor' => Proc.new { |category, record|
          # skip Antarctica - PostGIS doesn't know how to reproject it
          next if (record["name"] == 'Antarctica')

          # check whether the country already exists
          [Location.where(
            :category => 'country').where(
            ["lower(name) = ?", record["name"].downcase]).first ||
           Location.create!(
            :name => record["name"],
            :category => category,
            :props => { 'iso_a2' => record["iso_a2"] },
            :parents => {})]
        }
      },
      {
        'category' => 'country',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_countries_lakes.zip',
        'zipfile' => 'ne_110m_admin_0_countries_lakes.zip',
        'shapefile' => 'ne_110m_admin_0_countries_lakes.shp',
        'srid' => '4326',
        'geom_field' => 'area',
        'processor' => Proc.new { |category, record|
          # skip Antarctica - PostGIS doesn't know how to reproject it
          next if (record["name"] == 'Antarctica')

          # check whether the country already exists
          [Location.where(
            :category => 'country').where(
            ["lower(name) = ?", record["name"].downcase]).first ||
           Location.create!(
            :name => record["name"],
            :category => category,
            :props => { 'iso_a2' => record["iso_a2"] },
            :parents => {})]
        }
      },
      {
        'category' => 'state',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'zipfile' => 'ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'shapefile' => 'ne_10m_admin_1_states_provinces_lakes_shp.shp',
        'srid' => '4326',
        'geom_field' => 'raw_area',
        'processor' => Proc.new { |category, record| 
          next if (record['admin'] == 'Antarctica')

          # TODO this query lops off the part of Alaska that is west of 180W.
          # update locations set raw_area = ST_Difference(raw_area, st_multi(ST_GeomFromText('POLYGON((178 0, 178 85, 170 85, 170 0, 178 0))', 4326))) WHERE name = 'Alaska'

          parent = Location.where("category = 'country' AND props -> 'iso_a2' = '#{record["iso_a2"]}'").first

          # check for existing state
          location = Location.where(
            :category => 'state').where(
            :name => record["name"])

          if (parent)
            location = location.where(["exist(parents, ?::text)", parent.id])
          end

          if (location.first.nil?) 
            # only the US uses code_local, from which the FIPS code can be parsed.
            # non-US FIPS codes will be retrieved from geonames later.
            uids = { 'postal' => record['postal'] }
            if (record['iso_a2'] == 'US')
              uids['fips'] = record["code_local"][2..3]

              # this file has the wrong FIPS code for MN
              if (uids['postal'] == "MN")
                uids['fips'] = '27'
              end
            end

            [Location.create!(
              :name => record["name"],
              :category => category,
              :props => uids,
              :parents => parent.nil? ? {} : {parent.id => 'in'})]
          else
            [location.first]
          end
        }
      },
      {
        'category' => 'state',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_1_states_provinces_lakes_shp.zip',
        'zipfile' => 'ne_50m_admin_1_states_provinces_lakes_shp.zip',
        'shapefile' => 'ne_50m_admin_1_states_provinces_lakes_shp.shp',
        'srid' => '4326',
        'geom_field' => 'area',
        'processor' => Proc.new { |category, record| 
          next if (record['admin'] == 'Antarctica')

          # TODO this query lops off the part of Alaska that is west of 180W.
          # update locations set raw_area = ST_Difference(raw_area, st_multi(ST_GeomFromText('POLYGON((178 0, 178 85, 170 85, 170 0, 178 0))', 4326))) WHERE name = 'Alaska'

          parent = Location.where("category = 'country' AND props -> 'iso_a2' = '#{record["iso_a2"]}'").first

          # check for existing state
          location = Location.where(
            :category => 'state').where(
            :name => record["name"])

          if (parent)
            location = location.where(["exist(parents, ?::text)", parent.id])
          end

          if (location.first.nil?) 
            # only the US uses code_local, from which the FIPS code can be parsed.
            # non-US FIPS codes will be retrieved from geonames later.
            uids = { 'postal' => record['postal'] }
            if (record['iso_a2'] == 'US')
              uids['fips'] = record["code_local"][2..3]

              # this file has the wrong FIPS code for MN
              if (uids['postal'] == "MN")
                uids['fips'] = '27'
              end
            end

            [Location.create!(
              :name => record["name"],
              :category => category,
              :props => uids,
              :parents => parent.nil? ? {} : {parent.id => 'in'})]
          else
            [location.first]
          end
        }
      },
      {
        'category' => 'county',
        'url' => 'http://www2.census.gov/geo/tiger/TIGER2012/COUNTY/tl_2012_us_county.zip',
        'zipfile' => 'tl_2012_us_county.zip',
        'shapefile' => 'tl_2012_us_county.shp',
        'srid' => '4269',
        'tolerance' => '4000',
        'processor' => Proc.new {|category, record|
          # i hate encoding
          name = record["NAME"].force_encoding('ISO-8859-1').encode('UTF-8')
          parent = Location.where("category = 'state' AND props -> 'fips' = '#{record["STATEFP"]}'").first

          # check for existing county
          location = Location.where(
            :category => 'county').where(
            :name => name)

          if (parent)
            location = location.where(["exist(parents, ?::text)", parent.id])
          end

          [location.first || 
          Location.create!(
            :name => name,
            :category => category,
            :props => {'fips' => record["COUNTYFP"]},
            :parents => parent.nil? ? {} : {parent.id => 'in'})]
        }
      },
    ].each do |attrs|
      process_shapefile(attrs)
    end

    # geonames has FIPS codes for non-US states/provinces
    url = 'http://download.geonames.org/export/dump/admin1CodesASCII.txt'
    txtfile = 'admin1CodesASCII.txt'
    puts "downloading file #{url}"
    unless (File.file?(File.join(DATA_DIR, txtfile)))
      curl_cmd = "curl -L -o #{DATA_DIR}/#{txtfile} #{url}"
      system curl_cmd
    end

    File.open("#{DATA_DIR}/#{txtfile}").each do |record|
      attrs = record.force_encoding('ISO-8859-1').encode('UTF-8').split("\t")

      codes = /^(?<country>[A-Z]{2})\.(?<fips>\w+)/.match(attrs[0])

      # find the state
      country = Location.where(category: 'country').where(
        ["props -> 'iso_a2' = ?", codes[:country]])
      
      unless (country.first)
        next
      end

      state = Location.where(category: 'state').where(
        ["lower(name) = ?", attrs[1].downcase]).where(
        "parents ? #{country.first.id}::text")

      unless (state.first)
        next
      end

      puts "#{state.first.name}, #{country.name} - FIPS = #{codes[:fips]}"

      state.connection.execute("UPDATE locations SET props = props || hstore('fips', '#{codes[:fips]}') WHERE id = #{state.first.id}")
    end

    # the best city list I could find is a TSV from geonames.  it isn't a shapefile, but 
    # shapes can be determined from points
    url = 'http://download.geonames.org/export/dump/cities1000.zip'
    zipfile = 'cities1000.zip'
    tsvfile = 'cities1000.txt'
    cat = 'city'
    puts "Downloading file #{url}"
    unless (File.directory?(File.join(DATA_DIR, cat)))
      Dir.mkdir(File.join(DATA_DIR, cat))
    end

    unless (File.file?(File.join(DATA_DIR, cat, tsvfile)))
      curl_cmd = "curl -L -o #{DATA_DIR}/#{cat}/#{zipfile} #{url}"
      unzip_cmd = "unzip -d #{DATA_DIR}/#{cat}/ #{DATA_DIR}/#{cat}/#{zipfile}"
      system curl_cmd
      system unzip_cmd
    end

    num_records = %x{wc -l #{DATA_DIR}/#{cat}/#{tsvfile}}.split.first.to_i
    puts "#{cat} file contains #{num_records} records."

    i = 0
    File.open("#{DATA_DIR}/#{cat}/#{tsvfile}").each do |record|
      attrs = record.force_encoding('ISO-8859-1').encode('UTF-8').split("\t")

      i += 1

      # for now, only load supported countries
      next unless (['US', 'CA'].include?(attrs[8]))

      puts "(#{i} of #{num_records}) #{attrs[1]}, #{attrs[10]}, #{attrs[8]}"

      country = Location.where("category = 'country' AND props -> 'iso_a2' = '#{attrs[8]}'").first

      # if the country wasn't loaded, skip the cities
      next if country.nil?

      # parent_id progresses down the tree as we find smaller admin divisions
      parent_ids = [country.id]

      # per docs, some countries use ISO codes, some countries use FIPS codes
      if (['US', 'CH', 'BE', 'ME'].include?(attrs[8]))
        state = Location.where("category = 'state' AND parents ? '#{country.id}' AND props -> 'postal' = '#{attrs[10]}'").first
      else
        state = Location.where("category = 'state' AND parents ? '#{country.id}' AND props -> 'fips' = '#{attrs[10]}'").first
      end

      unless (state.nil?)
        parent_ids = [state.id]
      end

      # find the counties, if any
      counties = Location.where(category: 'county').where(
        "parents ? '#{parent_ids.first}'").where(
        "raw_area ~ ST_GeomFromEWKT('SRID=4326;POINT(#{attrs[5]} #{attrs[4]})')")

      unless (counties.empty?)
        parent_ids = counties.collect {|c| c.id }
      end

      # check for existing city - we can isolate by population until 
      # the file is updated, at which point the parenting issues will
      # hopefully be sorted out
      location = Location.where(
        :category => 'city', :name => attrs[1]).where(
        "props -> 'pop' = '#{attrs[14]}'"
      ).first

      if (location)
        location.parents = parent_ids.inject({}) { |h, id| h[id] = 'near'; h }
        location.save!
      else
        location = Location.create!(
          :name => attrs[1],
          :category => cat,
          :props => {'pop' => attrs[14]},
          :always_show => (['PPLA', 'PPLC'].include?(attrs[7])),
          :parents => parent_ids.inject({}) { |h, id| h[id] = 'near'; h }
        )
      end

      location.connection.update_sql("UPDATE locations SET raw_area = ST_Multi(ST_Transform(ST_Expand(ST_Transform(ST_GeomFromEWKT('SRID=4326;POINT(#{attrs[5]} #{attrs[4]})'), 900913), 20000), #{DB_SRID})) WHERE id = #{location.id}")
      location.connection.update_sql("UPDATE locations SET area = raw_area WHERE id = #{location.id}")
    end
  end

  desc "Simplify as much as possible without disappearing"
  task :max_simplify => :environment do
    maximum_tolerance = {}
    current_tolerance = 500

    while (current_tolerance < 30000)
      puts "tolerance = #{current_tolerance + 500}"

      query = "
UPDATE locations 
   SET area = ST_Transform(ST_Multi(ST_SimplifyPreserveTopology(ST_Transform(raw_area, 900913), #{current_tolerance + 500})), 4326) 
 WHERE category = 'state'
   AND parents ?| ARRAY['38']
"
      if (maximum_tolerance.keys.size > 0)
        query += " AND id NOT IN (#{maximum_tolerance.keys.join(',')})"
      end

      Location.connection.update_sql(query)

      Location.where(category: 'state').each do |l|
        if (!maximum_tolerance.has_key?(l.id) && l.area.nil?)
          maximum_tolerance[l.id] = current_tolerance
        end
      end

      current_tolerance += 500
    end

    maximum_tolerance.each do |id, tol|
      Location.connection.update_sql("
UPDATE locations 
   SET area = ST_Transform(ST_Multi(ST_SimplifyPreserveTopology(ST_Transform(raw_area, 900913), #{tol})), 4326) 
 WHERE id = #{id}
 ")
    end
  end

  desc "Load simplified US states"
  task :simple_us_states => :environment do
    require 'rgeo/geo_json'

    DATA_DIR = Rails.root.join('lib', 'data', 'location')
    unless (File.file?(File.join(DATA_DIR, 'state', 'us_states.js')))
      curl_cmd = "curl -L -o #{DATA_DIR}/state/us_states.js http://leafletjs.com/examples/us-states.js"
      system curl_cmd
    end

    file = File.open("#{DATA_DIR}/state/us_states.js", "r")
    file_string = file.read.gsub(/^.*?=\ /, '')[0..-3]
    states = RGeo::GeoJSON.decode(file_string, :json_parser => :json)

    states.each do |state|
      l = Location.where(category: 'state', name: state['name']).first

      unless (l.nil?)
        puts "loading #{state['name']} (#{l.id})"
        l.connection.execute("
UPDATE locations
   SET area = ST_Multi(ST_GeomFromEWKT('SRID=4326;#{state.geometry.as_text}'))
 WHERE id = #{l.id}")
      end
    end

    file.close
  end
end
