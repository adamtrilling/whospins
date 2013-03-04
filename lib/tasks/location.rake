namespace :location do
  desc "Load data from shapefiles from scratch"
  task :load => :environment do

    DATA_DIR = Rails.root.join('lib', 'data', 'location')
    SRID = Location.connection.select_all("SELECT Find_SRID('public', 'locations', 'raw_area') AS srid").first["srid"]
    TOLERANCE = 1
    SIMPLIFY = "ST_Simplify(raw_area, #{TOLERANCE})"

    shapefiles = { 
      'country' => {
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries_lakes.zip',
        'zipfile' => 'ne_10m_admin_0_countries_lakes.zip',
        'shapefile' => 'ne_10m_admin_0_countries_lakes.shp',
        'uid' => 'iso_a2'
      },
      'state' => {
        'url' => 'http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'zipfile' => 'ne_10m_admin_1_states_provinces_lakes_shp.zip',
        'shapefile' => 'ne_10m_admin_1_states_provinces_lakes_shp.shp',
        'parent_uid' => 'iso_a2'
      }
    }

    puts "Removing existing data"
    Location.destroy_all
    FileUtils.rm_rf(File.join(Rails.root, 'public', 'tiles'))

    puts "Loading data - SRID = #{SRID}"

    shapefiles.each do |cat, attrs|
      puts "Downloading shapefile"
      unless (File.directory?(File.join(DATA_DIR, cat)))
        Dir.mkdir(File.join(DATA_DIR, cat))
      end

      unless (File.file?(File.join(DATA_DIR, cat, attrs['shapefile'])))
        curl_cmd = "curl -L -o #{DATA_DIR}/#{cat}/#{attrs['zipfile']} #{attrs['url']}"
        unzip_cmd = "unzip -d #{DATA_DIR}/#{cat}/ #{DATA_DIR}/#{cat}/#{attrs['zipfile']}"
        puts "curl: #{curl_cmd}"
        puts "unzip: #{unzip_cmd}"
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

          country = Location.create!(
            :name => record["name"],
            :category => cat,
            :uid => attrs.has_key?('uid') ? record[attrs['uid']] : nil,
            :parent_id => parent.nil? ? nil : parent.id
          )
          puts "done"

          country.connection.update_sql("UPDATE locations SET raw_area = ST_GeomFromText('#{record.geometry.as_text}', #{SRID}) WHERE id = #{country.id}")
          country.connection.update_sql("UPDATE locations SET area = raw_area WHERE id = #{country.id}")
          i += 1
        end
      end
    end
  end
end