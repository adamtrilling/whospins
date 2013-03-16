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
      m.buffer = 32

      # find locations in the current buffer
      buffered_locations = Location.where("raw_area && 'SRID=4326;#{m.buffered_bounds.reproject(m.srs, 'epsg:4326').to_wkt}'")      

      # find the countries that are and aren't supported by the app
      unsupported_countries = buffered_locations.where(:category => 'country').where("name NOT IN (?)", COUNTRY_LIST)
      supported_countries = buffered_locations.where(:category => 'country').where(:name => COUNTRY_LIST)

      line_style = {
        'stroke' => '#002240',
        'weight' => '1',
        'line-join' => 'round',
        'fill' => '#CCCCCC'
      }

      label_style = {
        'text-field' => 'name',
        'weight' => '0.5',
        'text-stroke-color' => '#000000',
        'text-outline-color' => '#ffffffcc',
        'text-outline-weight' => '2',
        'font' => 'Avenir Light, Light Oblique 8',
        'letter-spacing' => '1'
      }

      m.ar_layer do |l|

        l.query unsupported_countries.select("raw_area").to_sql do |q|
          # normal black border, gray fill
          q.styles line_style
        end

        # states/provinces in supported countries
        l.query buffered_locations.select("name, raw_area").where(:parent_id => supported_countries.to_a.map(&:id)).to_sql do |q|
          # thin white border, gray fill
          style = line_style.merge('stroke' => '#F0F0F0')

          if ((4..5).include?(params[:z].to_i))
            style = style.merge(label_style)
          end

          q.styles style

        end
        l.query supported_countries.select("name, raw_area").to_sql do |q|
          # normal black border, transparent gray fill so we don't cover up the state lines
          style = line_style.merge('fill' => '#CCCCCC00')

          if (params[:z].to_i < 4)
            style = style.merge(label_style)
          end

          q.styles style

        end

        # cities only get labled if their population is high enough for the zoom
        city_labels = {
          '6' => 1000000,
          '7' => 500000,
          '8' => 250000,
          '9' => 100000,
          '10' => 50000,
          '11' => 25000
        }
        if (city_labels.has_key?(params[:z]))
          # temporary buffering until cities have area too
          city_locations = Location.where("point && 'SRID=4326;#{m.buffered_bounds.reproject(m.srs, 'epsg:4326').to_wkt}'")
          l.query city_locations.select("name", "point").where(:category => 'city').where("(props -> 'pop')::int >= #{city_labels[params[:z]]}").to_sql do |q|
            q.styles label_style
          end
        end
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
