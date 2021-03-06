class LocationsController < ApplicationController
  caches_page :overlay, :children

  def overlay
    # these are pesky in browser-side caches.  expire them immediately and
    # let the browser get them from the server cache until I can figure
    # out something smarter
    expires_now

    @locations = Location.includes(:parent, :users).
      where(["geojson IS NOT NULL AND num_users > 0 AND parent_id = ?", params[:id]])

    respond_to do |format|
      format.json do 
        render :json => {
          type: "FeatureCollection",
          features: @locations.collect do |loc|
            { type: 'Feature',
              id: loc.id,
              properties: {
                category: loc.category,
                display_name: loc.display_name,
                num_users: loc.users.size,
                percentile: loc.percentile
              },
              geometry: JSON.parse(loc.geojson)
            }
          end
        }.to_json
      end
    end
  end

  def users
    @location = Location.includes(:users => [:authorizations]).find(params[:id])
    @users = @location.users

    respond_to do |format|
      format.json do
        render :json => {
          users: @users.sort_by(&:sort_name).collect do |user|
            { name: user.name,
              profiles: user.authorizations.sort_by(&:provider).collect do |auth|
                { provider: auth.provider,
                  profile_url: auth.profile_url
                }
              end
            }
          end
        }
      end
    end
  end

  def children
    @locations = Location.where(
      ["parent_id = ?", params[:id]]
    ).select(
      :id, :name
    ).order(:name)

    respond_to do |format|
      format.json do        
        render :json => @locations.to_json
      end
    end
  end
end
