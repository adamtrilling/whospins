class UsersController < ApplicationController
  def update
    @user = User.find(params[:id])

    # handle the location, if given
    if (params[:location])
      categories = ['country', 'state', 'county', 'city']
      location = nil
      categories.each_with_index do |cat, i|
        # check that the location, if given, exists, is the right category,
        # and has the correct parent
        if (params[:location][cat])
          # don't throw an exception if not found, since we're going to test
          # for nil later anyway
          possible_location = Location.find_by_id(params[:location][cat])

          if (possible_location && possible_location.category == cat)
            # don't check parentage for country
            if (i > 0)
              if (possible_location.parent_id == location.id)
                location = possible_location
                status = "OK"
              else
                status = "invalid parent"
                break
              end
            else
              location = possible_location
              status = "OK"
            end
          end
        end
      end

      if (location.nil?)
        status = "no location given"
      else
        status = "OK"
        @user.location = location
      end
    end

    if (@user.save)
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
      # recursively find the user's locations
      locations = {}
      loc = current_user.location
      while (!loc.nil?)
        locations[loc.category] = loc.id
        loc = loc.parent
      end

      @user_data = {
        :id => current_user.id,
        :location => locations
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