class LocationsController < ApplicationController
  caches_page :overlay, :children

  def overlay
    # these are pesky in browser-side caches.  expire them immediately and
    # let the browser get them from the server cache until I can figure
    # out something smarter
    expires_now

    # user counts needs to be a subquery table so that we can use the counts
    # in the window function and the where clause.  this won't work in any 
    # database other than postgresql.
    @locations = Location.select(
      "*, percent_rank() OVER (ORDER BY num_users)"
    ).where(
      :category => params[:id]
    ).where(
      "num_users > 0"
    ).includes(:users)

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