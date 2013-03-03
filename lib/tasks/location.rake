namespace :location do
  desc "Load data from shapefiles from scratch"
  task :load => :environment do

    DATA_DIR = Rails.root.join('lib', 'data', 'location')
    SRID = Location.connection.select_all("SELECT Find_SRID('public', 'locations', 'raw_area') AS srid").first["srid"]
    TOLERANCE = 1
    SIMPLIFY = "ST_Simplify(raw_area, #{TOLERANCE})"

    puts "removing existing data"
    Location.destroy_all
    FileUtils.rm_rf(File.join(Rails.root, 'public', 'tiles'))

    puts "Loading data - SRID = #{SRID}"

    RGeo::Shapefile::Reader.open("#{DATA_DIR}/countries/ne_10m_admin_0_countries_lakes.shp") do |file|
      puts "Countries file contains #{file.num_records} records."

      i = 1
      file.each do |record|
        print "(#{i} of #{file.num_records}) #{record["name_sort"]}..."
        
        country = Location.create!(
          :name => record["name_sort"],
          :category => 'country',
          :fips => record['fips'],
          :parent_id => nil
        )
        puts "done"

        # ST_Transform doesn't like the South Pole
        # next if record["NAME"] == "Antarctica"

        country.connection.update_sql("UPDATE locations SET raw_area = ST_GeomFromText('#{record.geometry.as_text}', #{SRID}) WHERE id = #{country.id}")
        country.connection.update_sql("UPDATE locations SET area = #{SIMPLIFY} WHERE id = #{country.id}")
        i += 1
      end
    end

    puts "importing states"

    RGeo::Shapefile::Reader.open("#{DATA_DIR}/us_states/tl_2012_us_state.shp") do |file|
      puts "States file contains #{file.num_records} records."

      us = Location.where(:category => 'country', :fips => 'US').first

      i = 1
      file.each do |record|
        print "(#{i} of #{file.num_records}) #{record["NAME"]}..."
        state = Location.create!(
          :name => record["NAME"],
          :category => 'state',
          :fips => record["STATEFP"],
          :parent_id => us.id
        )
        # do the geography as raw SQL - it's MUCH faster
        state.connection.update_sql("UPDATE locations SET raw_area = ST_GeomFromText('#{record.geometry.as_text}', #{SRID}) WHERE id = #{state.id}")
        state.connection.update_sql("UPDATE locations SET area = #{SIMPLIFY} WHERE id = #{state.id}")
        puts "done"
        i += 1
      end
    end

    puts "importing counties"
    RGeo::Shapefile::Reader.open("#{DATA_DIR}/us_counties/tl_2012_us_county.shp") do |file|
      puts "Counties file contains #{file.num_records} records."

      i = 1
      file.each do |record|
        state = Location.where(:category => 'state', :fips => record["STATEFP"]).first
        next if state.nil?
        print "(#{i} of #{file.num_records}) #{record["NAME"]} County, #{state.name}..."
        county = Location.create!(
          # i hate encoding
          :name => record["NAME"].force_encoding('ISO-8859-1').encode('UTF-8'),
          :category => 'county',
          :fips => record["COUNTYFP"],
          :parent_id => state.id
        )

        county.connection.update_sql("UPDATE locations SET raw_area = ST_GeomFromText('#{record.geometry.as_text}', #{SRID}) WHERE id = #{county.id}")
        county.connection.update_sql("UPDATE locations SET area = #{SIMPLIFY} WHERE id = #{county.id}")

        puts "done"
        i += 1
      end
    end

    # puts "importing cities"

    # # there's one city shapefile per state, named by FIPS
    # states.each do |fips, state| 
    #   puts "#{state.name} (#{fips})"
    #   RGeo::Shapefile::Reader.open("#{DATA_DIR}/tl_2012_#{fips}_place.shp") do |file|
    #     puts "\tPlaces file contains #{file.num_records} records."
    #     i = 1
    #     file.each do |record|
    #       print "(#{i} of #{file.num_records}) #{record["NAME"]}, #{state.name}..."
    #       city = Location.create(
    #         :name => record["NAME"].force_encoding('ISO-8859-1').encode('UTF-8'),
    #         :category => 'city',
    #         :parent_id => state.id
    #       )

    #       if (record.geometry)
    #         city.connection.update_sql("UPDATE locations SET area = ST_GeomFromText('#{record.geometry.as_text}') WHERE id = #{city.id}")
    #       end

    #       puts "done"
    #       i += 1
    #     end
    #   end
    # end
  end

  desc "Load data from shapefiles, preserving data"
  task :refresh => :environment do
    puts "updating"
  end
end