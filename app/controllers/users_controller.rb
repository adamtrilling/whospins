class UsersController < ApplicationController
  def index
    render :text => "Number of users: #{User.count}"
  end

  def update
    @user = User.find(params[:id])

    # handle the location, if given
    if (params[:location])
      @user.old_location_ids = @user.location_ids
      @user.location_ids = params[:location].values
    end

    if (@user.save)
      # expire the map overlays.  we want to expire ALL of them, 
      # which we can't do using exipre_page.
      FileUtils.rm_rf(
        File.join(
          Whospins::Application.config.action_controller.page_cache_directory, 
            'locations', 'overlay'
        )
      )

      status = "OK"
    else
      status = "Failed to save user"
    end

    respond_to do |format|
      format.json do 
        render :json => {"status" => status}.to_json
      end
    end
  end

  def current
    if (current_user)
      @user_data = {
        :id => current_user.id,
        :location => current_user.locations.inject({}) {|hash, loc| 
          hash[loc.category] = loc.id
          hash
        }
      }
    else
      @user_data = {}
    end

    respond_to do |format|
      format.json do
        render :json => @user_data.to_json
      end
    end
  end
end