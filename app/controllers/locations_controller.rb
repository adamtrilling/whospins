class LocationsController < ApplicationController
  caches_page :index

  def overlay
    @locations = Location.select(
      'locations.*, percent_rank() OVER (ORDER BY num_users)'
    ).where(
      :category => params[:id]
    ).where("num_users > 0")

    respond_to do |format|
      format.json do 
        render 'overlay'
      end
    end
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