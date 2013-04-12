class LocationsController < ApplicationController
  caches_page :index, :overlay

  def overlay
    # user counts needs to be a subquery table so that we can use the counts
    # in the window function and the where clause.  this won't work in any 
    # database other than postgresql.
    @locations = Location.select(
      'locations.*, lu.num_users, percent_rank() OVER (ORDER BY lu.num_users)'
    ).joins(
      ", (SELECT location_id, COUNT(user_id) as num_users 
          FROM locations_users
      GROUP BY location_id) AS lu"
    ).where(
      "locations.id = lu.location_id"
    ).where(
      :category => params[:id]
    ).where(
      "num_users > 0"
    )

    Rails.logger.info("query = #{@locations.to_sql}")

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