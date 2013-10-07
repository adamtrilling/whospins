class LocationsController < ApplicationController
  caches_page :overlay, :children

  def overlay
    # these are pesky in browser-side caches.  expire them immediately and
    # let the browser get them from the server cache until I can figure
    # out something smarter
    expires_now

    @locations = Location.where("num_users > 0").includes(:users => :authorizations)

    if (params[:id].to_i > 0)
      # you can't use ? operators with bind parameters.  but we've already
      # verified that params[:id] is an integer, so it is safe to pass without
      # binding. 
      # this query selects, by line:
      # 1) the current location's children
      # 2) the current location's siblings
      # 3) all states (change to countries when there are more of them)
      # 4) exclude the location itself and its country  
      @locations = @locations.where("(
parents ? '#{params[:id].to_i}' OR
parents ?| (select akeys(parents) from locations where id = #{params[:id].to_i}) OR 
category = 'state') AND
id != #{params[:id].to_i} AND 
id NOT IN (select skeys(parents)::integer FROM locations where id = #{params[:id].to_i})")
    else
      @locations = @locations.where(category: params[:id])
    end

    respond_to do |format|
      format.json do 
        render 'overlay'
      end
    end
  end

  def children
    @locations = Location.where(
      # you can't use the ? operator with bind varibles...
      ["exist(parents, ?)", params[:id]]
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