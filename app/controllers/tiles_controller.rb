require 'simpler_tiles'

class TilesController < ApplicationController

  TILE_CACHE = File.join(Rails.root, 'public', 'tiles')

  def show
    # generate the tile from PostGIS
    map = SimplerTiles::Map.new do |m|
      Rails.logger.info("Setting params")
      m.srs     = "EPSG:4326"
      m.slippy params[:x].to_i, params[:y].to_i, params[:z].to_i
      m.bgcolor = '#B4E3F0'

      m.ar_layer do |l|

        # Grab all of the data from the shapefile
        l.query "select * from locations" do |q|

          # Add a style for stroke, fill, weight and set the line-join to be round
          q.styles 'stroke' => '#002240',
                   'weight' => '1',
                'line-join' => 'round',
                     'fill' => '#CCCCCC'
        end
      end
    end

    Rails.logger.info("writing file")
    png = map.to_png
    Rails.logger.info("size = #{png.size}")    
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

      Rails.logger.info("returning tile")
      # send the tile to the browser
      send_data map.to_png, :type => "image/png", :filename => "#{params[:y]}.png"
    else
      Rails.logger.info("tile was empty")
      raise "empty tile"
    end
  end
end
