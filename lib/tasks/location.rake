require 'fileutils'

namespace :location do
  desc "Load data from shapefiles from scratch"
  task :load => :environment do

    DATA_DIR = Rails.root.join('lib', 'data', 'location')
    FileUtils.mkdir_p DATA_DIR

    DB_SRID = Location.connection.select_all("SELECT Find_SRID('public', 'locations', 'raw_area') AS srid").first["srid"]

    puts "Removing existing data"
    Location.destroy_all
    FileUtils.rm_rf(File.join(Whospins::Application.config.action_controller.page_cache_directory, 'tiles'))

    puts "Loading data - DB_SRID = #{DB_SRID}"

    # this is weird and abuses metaprogramming a bit.  but it saves a lot of code 
    # repetition.  the processor needs to return either the locations it built for 
    # the current record, or nil if there is a failure or an intentional skip.  if
    # nil is returned, the area isn't added to the database.
    shapefiles = [ 
      {
        'category' => 'country',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries_lakes.zip',
        'zipfile' => 'ne_10m_admin_0_countries_lakes.zip',
        'shapefile' => 'ne_10m_admin_0_countries_lakes.shp',
        'srid' => '4326',
        'tolerance' => '1100',
        'processor' => Proc.new { |category, record|
          # skip Antarctica - PostGIS doesn't know how to reproject it
          next if (record["name"] == 'Antarctica')

          [Location.create!(
            :name => record["name"],
            :category => category,
            :props => { 'iso_a2' => record["iso_a2"] },
            :parent_id => nil)]
        }
      },
      {
        'category' => 'state',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'zipfile' => 'ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'shapefile' => 'ne_10m_admin_1_states_provinces_lakes_shp.shp',
        'srid' => '4326',
        'tolerance' => '1100',
        'processor' => Proc.new { |category, record| 
          next if (record['admin'] == 'Antarctica')

          parent = Location.where("category = 'country' AND props -> 'iso_a2' = '#{record["iso_a2"]}'").first

          # only the US uses code_local, from which the FIPS code can be parsed
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
            :parent_id => parent.nil? ? nil : parent.id)]
        }
      },
      {
        'category' => 'county',
        'url' => 'http://www2.census.gov/geo/tiger/TIGER2012/COUNTY/tl_2012_us_county.zip',
        'zipfile' => 'tl_2012_us_county.zip',
        'shapefile' => 'tl_2012_us_county.shp',
        'srid' => '4269',
        'tolerance' => '2000',
        'processor' => Proc.new {|category, record|
          parent = Location.where("category = 'state' AND props -> 'fips' = '#{record["STATEFP"]}'").first

          [Location.create!(
            :name => record["NAME"].force_encoding('ISO-8859-1').encode('UTF-8'),
            :category => category,
            :props => {'fips' => record["COUNTYFP"]},
            :parent_id => parent.nil? ? nil : parent.id)]
        }
      },
      # {
      #   'category' => 'county',
      #   'url' => 'http://www.baruch.cuny.edu/geoportal/data/esri/usa/census/counties.zip',
      #   'zipfile' => 'counties.zip',
      #   'shapefile' => 'counties.shp',
      #   'srid' => '4326',
      #   'processor' => Proc.new { |category, record| 
      #     next if record.geometry.nil?

      #     parent = Location.where("category = 'state' AND props -> 'fips' = '#{record["STATE_FIPS"]}'").first

      #     [Location.create!(
      #       :name => record["NAME"],
      #       :category => category,
      #       :props => {'fips' => record['CNTY_FIPS']},
      #       :parent_id => parent.nil? ? nil : parent.id)]
      #   }
      # },
      # {
      #   'category' => 'county',
      #   'url' => 'http://www.baruch.cuny.edu/geoportal/data/esri/usa/census/dtl_cnty.zip',
      #   'zipfile' => 'dtl_cnty.zip',
      #   'shapefile' => 'dtl_cnty.shp',
      #   'srid' => '4326',
      #   'processor' => Proc.new { |category, record|
      #     next if record.geometry.nil?

      #     # skip existing counties
      #     next if (Location.where("category = 'county' AND props -> 'fips' = #{record["CNTY_FIPS"]}"))

      #     parent = Location.where("category = 'state' AND props -> 'fips' = '#{record["STATE_FIPS"]}'").first

      #     [Location.create!(
      #       :name => record["NAME"],
      #       :category => category,
      #       :props => {'fips' => record['CNTY_FIPS']},
      #       :parent_id => parent.nil? ? nil : parent.id)]
      #   }
      # },
    ]

    # # the US Census distributes files that are named
    # # by FIPS code
    # ["01", "02", "04", "05", "06", "08", "09", "10",
    #  "11", "12", "13", "15", "16", "17", "18", "19",
    #  "20", "21", "22", "23", "24", "25", "26", "28",
    #  "29", "30", "31", "32", "33", "34", "35", "36",
    #  "37", "38", "39", "40", "41", "42", "44", "45",
    #  "46", "47", "48", "49", "50", "51", "53", "54",
    #  "55", "56"].each do |fips|

    #   # counties
    #   shapefiles << {
    #     'category' => 'county',
    #     'area_type' => 'area',
    #     'url' => "http://www2.census.gov/geo/tiger/GENZ2010/gz_2010_#{fips}_060_00_500k.zip",
    #     'zipfile' => "gz_2010_#{fips}_060_00_500k.zip",
    #     'shapefile' => "gz_2010_#{fips}_060_00_500k.shp",
    #     'srid' => '4269',
    #     'processor' => Proc.new { |category, record| 
    #       parent = Location.where("category = 'state' AND props -> 'fips' = '#{fips}'").first

    #       [Location.create!(
    #         :name => record["NAME"].force_encoding('ISO-8859-1').encode('UTF-8'),
    #         :category => category,
    #         :props => {},
    #         :parent_id => parent.id
    #       )]
    #     }
    #   }
    # end

    shapefiles.each do |attrs|
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

              if (attrs['debug'])
                puts "record geometry type = #{record.geometry.class.to_s}"
                puts "raw sql = UPDATE locations SET raw_area = ST_Transform(ST_GeomFromText('#{record.geometry.as_text}', #{attrs['srid']}), #{DB_SRID}) WHERE id = #{loc.id}"
              end

              # if the shapefile contains points, make them into polygons
              if (record.geometry.is_a?(RGeo::Geos::FFIPointImpl))
                loc.connection.update_sql("UPDATE locations SET raw_area = ST_Multi(ST_Transform(ST_Expand(ST_Transform(ST_GeomFromText('#{record.geometry.as_text}', #{attrs['srid']}), 900913), 1000), #{DB_SRID})) WHERE id = #{loc.id}")
              else
                loc.connection.update_sql("UPDATE locations SET raw_area = ST_Transform(ST_GeomFromText('#{record.geometry.as_text}', #{attrs['srid']}), #{DB_SRID}) WHERE id = #{loc.id}")
              end

              if (attrs['tolerance'])
                # transform to Web Mercator before simplifying, because simplifying 
                # lat/lon geometries causes weird things to happen.  like the state 
                # of Michigan disappearing.
                loc.connection.update_sql("UPDATE locations SET area = ST_Transform(ST_Simplify(ST_Transform(raw_area, 900913), #{attrs['tolerance']}), #{DB_SRID}) WHERE id = #{loc.id}")
              else
                loc.connection.update_sql("UPDATE locations SET area = raw_area WHERE id = #{loc.id}")
              end
            end
          end
          i += 1
        end
      end
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
      next unless (['US'].include?(attrs[8]))

      puts "(#{i} of #{num_records}) #{attrs[1]}, #{attrs[10]}, #{attrs[8]}"

      country = Location.where("category = 'country' AND props -> 'iso_a2' = '#{attrs[8]}'").first

      # if the country wasn't loaded, skip the cities
      next if country.nil?

      # parent_id progresses down the tree as we find smaller admin divisions
      parent_id = country.id

      # per docs, some countries use ISO codes, some countries use FIPS codes
      if (['US', 'CH', 'BE', 'ME'].include?(attrs[8]))
        state = Location.where("category = 'state' AND parent_id = #{country.id} AND props -> 'postal' = '#{attrs[10]}'").first
      else
        state = Location.where("category = 'state' AND parent_id = #{country.id} AND props -> 'fips' = '#{attrs[10]}'").first
      end

      unless (state.nil?)
        parent_id = state.id
      end

      # find the county, if it exists
      county = Location.where("category = 'county' AND parent_id = #{parent_id} AND raw_area ~ ST_GeomFromEWKT('SRID=4326;POINT(#{attrs[5]} #{attrs[4]})')").first

      unless (county.nil?)
        parent_id = county.id
      end

      loc = Location.create!(
        :name => attrs[1],
        :category => cat,
        :props => {'pop' => attrs[14]},
        :always_show => (['PPLA', 'PPLC'].include?(attrs[7])),
        :parent_id => parent_id
      )

      loc.connection.update_sql("UPDATE locations SET raw_area = ST_Multi(ST_Transform(ST_Expand(ST_Transform(ST_GeomFromEWKT('SRID=4326;POINT(#{attrs[5]} #{attrs[4]})'), 900913), 1000), #{DB_SRID})) WHERE id = #{loc.id}")
      loc.connection.update_sql("UPDATE locations SET area = raw_area WHERE id = #{loc.id}")
    end
  end
end