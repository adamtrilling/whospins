namespace :location do
  desc "Load data from shapefiles from scratch"
  task :load => :environment do

    DATA_DIR = Rails.root.join('lib', 'data', 'location')
    SRID = Location.connection.select_all("SELECT Find_SRID('public', 'locations', 'raw_area') AS srid").first["srid"]

    puts "Removing existing data"
    Location.destroy_all
    FileUtils.rm_rf(File.join(Rails.root, 'public', 'tiles'))

    puts "Loading data - SRID = #{SRID}"

    # this is weird and abuses metaprogramming a bit.  but it saves a lot of code 
    # repetition.  the processor needs to return either the location it built for 
    # the current record, or nil if there is a failure or an intentional skip.  if
    # nil is returned, the area isn't added to the database.
    shapefiles = [ 
      {
        'category' => 'country',
        'area_type' => 'area',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries_lakes.zip',
        'zipfile' => 'ne_10m_admin_0_countries_lakes.zip',
        'shapefile' => 'ne_10m_admin_0_countries_lakes.shp',
        'tolerance' => '100',
        'processor' => Proc.new { |category, record|
          # skip Antarctica - PostGIS doesn't know how to reproject it
          next if (record["name"] == 'Antarctica')

          Location.create!(
            :name => record["name"],
            :category => category,
            :props => { 'iso_a2' => record["iso_a2"] },
            :parent_id => nil)
        }
      },
      {
        'category' => 'state',
        'area_type' => 'area',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'zipfile' => 'ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'shapefile' => 'ne_10m_admin_1_states_provinces_lakes_shp.shp',
        'tolerance' => '100',
        'processor' => Proc.new { |category, record| 
          next if (record['admin'] == 'Antarctica')

          parent = Location.where("category = 'country' AND props -> 'iso_a2' = '#{record["iso_a2"]}'").first

          # only the US uses code_local, from which the FIPS code can be parsed
          uids = { 'hasc' => record["code_hasc"] }
          if (record['iso_a2'] == 'US')
            uids['fips'] = record["code_local"][2..3]
          end

          Location.create!(
            :name => record["name"],
            :category => category,
            :props => uids,
            :parent_id => parent.nil? ? nil : parent.id)
        }
      },
      {
        'category' => 'city',
        'area_type' => 'point',
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places.zip',
        'zipfile' => 'ne_10m_populated_places.zip',
        'shapefile' => 'ne_10m_populated_places.shp',
        'processor' => Proc.new { |category, record| 
          # these are going to be displayed on the map, but not selectable.  so 
          # country is fine as a parent
          parent = Location.where("category = 'country' AND props -> 'iso_a2' = '#{record["ISO_A2"]}'").first
          
          Location.create!(
            :name => record["NAME"].force_encoding('ISO-8859-1').encode('UTF-8'),
            :category => category,
            :props => {'class' => record['FEATURECLA'], 'pop' => record['POP_MAX']},
            :parent_id => parent.nil? ? nil : parent.id)
        }
      }
    ]

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
          print "(#{i} of #{file.num_records}) #{record["name"]}..."
          puts "attrs: #{record.attributes}"

          if (attrs.has_key?('parent_uid')) 
            parent = Location.where(:uid => record[attrs['parent_uid']]).first
          end

          loc = attrs['processor'].call(cat, record)
          puts "done"

          unless (loc.nil?)
            if (attrs['area_type'] == 'area')
              loc.connection.update_sql("UPDATE locations SET raw_area = ST_GeomFromText('#{record.geometry.as_text}', #{SRID}) WHERE id = #{loc.id}")
              if (attrs['tolerance'])
                # transform to Web Mercator before simplifying, because simplifying 
                # lat/lon geometries causes weird things to happen.  like the state 
                # of Michigan disappearing.
                loc.connection.update_sql("UPDATE locations SET area = ST_Transform(ST_Simplify(ST_Transform(raw_area, 900913), #{attrs['tolerance']}), #{SRID}) WHERE id = #{loc.id}")
              else
                loc.connection.update_sql("UPDATE locations SET area = raw_area WHERE id = #{loc.id}")
              end
            else
              loc.connection.update_sql("UPDATE locations SET point = ST_GeomFromText('#{record.geometry.as_text}', #{SRID}) WHERE id = #{loc.id}")
            end              
          end
          i += 1
        end
      end
    end
  end
end