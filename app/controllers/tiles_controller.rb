require 'simpler_tiles'

class TilesController < ApplicationController

  TILE_CACHE = File.join(Rails.root, 'public', 'tiles')
  COUNTRY_LIST = ['United States', 'Canada']

  def show
    if (Rails.env == 'development')
      # tell the browser not to cache tiles in dev - otherwise, changes
      # to this function don't do anything.
      expires_now
    end

    map = SimplerTiles::Map.new do |m|
      m.srs     = "EPSG:4326"
      m.slippy params[:x].to_i, params[:y].to_i, params[:z].to_i
      m.bgcolor = '#B4E3F0'

      # find locations in the current buffer
      buffered_locations = Location.where("area && 'SRID=4326;#{m.buffered_bounds.reproject(m.srs, 'epsg:4326').to_wkt}'")

      # find the countries that are and aren't supported by the app
      unsupported_countries = buffered_locations.where(:category => 'country').where("name NOT IN (?)", COUNTRY_LIST)
      supported_countries = buffered_locations.where(:category => 'country').where(:name => COUNTRY_LIST)

      m.ar_layer do |l|
        Rails.logger.info "unsupported_countries sql = #{unsupported_countries.to_sql}"

        l.query unsupported_countries.select("area").to_sql do |q|
          # normal black border, gray fill
          q.styles 'stroke' => '#002240',
                   'weight' => '1',
                'line-join' => 'round',
                     'fill' => '#CCCCCC'
        end

        # states/provinces in supported countries
        l.query buffered_locations.select("area").where(:parent_id => supported_countries.to_a.map(&:id)).to_sql do |q|
          # thin white border, gray fill
          q.styles 'stroke' => '#F0F0F0',
                   'weight' => '.5',
                'line-join' => 'round',
                     'fill' => '#CCCCCC'          
        end
        l.query supported_countries.select("name", "point").to_sql do |q|
          # normal black border, transparent gray fill so we don't cover up the state lines
          q.styles 'stroke' => '#002240',
                   'weight' => '1',
                'line-join' => 'round',
                     'fill' => '#CCCCCC00'          
        end

        # # cities that get labeled
        # l.query buffered_locations.where(:category => 'city-point').where("(props -> 'pop')::int >= 100000").to_sql do |q|
        #   q.styles 'text-field' => 'name'
        # end
      end

    end

    png = map.to_png
    if (png)
      # cache the tile such that future accesses won't even hit rails
      unless (File.directory?(File.join(TILE_CACHE)))
        Dir.mkdir(File.join(TILE_CACHE))
      end

      unless (File.directory?(File.join(TILE_CACHE, params[:z])))
        Dir.mkdir(File.join(TILE_CACHE, params[:z]))
      end

      unless (File.directory?(File.join(TILE_CACHE, params[:z], params[:x])))
        Dir.mkdir(File.join(TILE_CACHE, params[:z], params[:x]))
      end

      File.open(File.join(TILE_CACHE, params[:z], params[:x], "#{params[:y]}.png"), 'wb') do |file|
        file.write(map.to_png)
      end

      # send the tile to the browser
      send_data map.to_png, :type => "image/png", :filename => "#{params[:y]}.png"
    else
      Rails.logger.info("tile was empty")
      raise "empty tile"
    end
  end
end
