require 'simpler_tiles'

class TilesController < ApplicationController

  caches_page :show

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

      # font styles vary by OS :(
      if (Rails.env == 'development')
        font = 'Avenir Light, Light Oblique 9'
      else
        font = 'DejaVu Sans,DejaVu Sans Light 9'
      end

      label_style = {
        'text-field' => 'name',
        'weight' => '0.5',
        'text-stroke-color' => '#000000',
        'text-outline-color' => '#ffffffcc',
        'text-outline-weight' => '2',
        'font' => font,
        'letter-spacing' => '1'
      }

      m.ar_layer do |l|

        l.query unsupported_countries.select("raw_area").to_sql do |q|
          # normal black border, gray fill
          q.styles line_style
        end

        # states/provinces in supported countries
        l.query buffered_locations.select("name, raw_area").where(:parent_id => supported_countries.to_a.map(&:id), :category => 'state').to_sql do |q|
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

        # cities only get labeled if their population is high enough for the zoom or the 
        # "always_show" flag is set
        city_labels = {
          '6' => 1000000,
          '7' => 500000,
          '8' => 250000,
          '9' => 100000,
          '10' => 50000,
          '11' => 25000
        }
        if (city_labels.has_key?(params[:z]))
          l.query buffered_locations.select("name", "raw_area").where(:category => 'city').where("((props -> 'pop')::int >= #{city_labels[params[:z]]}) OR always_show IS TRUE").order("(props -> 'pop')::int DESC").to_sql do |q|
            q.styles label_style
          end
        end
      end

    end

    unless (map.to_png)
      Rails.logger.info("tile was empty")
      raise "empty tile"
    end

    send_data map.to_png, :type => "image/png", :filename => "#{params[:y]}.png"
  end
end
