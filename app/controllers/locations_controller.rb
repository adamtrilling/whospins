class LocationsController < ApplicationController
  caches_page :index

  def index
    @locations = Location.where(:category => 'state').where(:parent_id => Location.supported_country_ids.map(&:id))
  end

  def children
    @locations = Location.where(
      :parent_id => params[:id]
    ).select(
      :id, :name, :category
    ).group_by(
      &:category
    # simplify the data structure
    ).inject({}) { |h, (k, v)|
      h[k] = v.sort_by(&:name).collect { |loc|
        { "id" => loc.id, "name" => loc.name }
      }; h
    }

    # no reason to use jbuilder here because to_json works fine
    respond_to do |format|
      format.json do        
        render :json => @locations.to_json
      end
    end
  end
end