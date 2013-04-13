class UsersController < ApplicationController
  def update
    @user = User.find(params[:id])

    # handle the location, if given
    if (params[:location])
      @user.locations.clear
      params[:location].each do |cat, loc|
        @user.locations << Location.find(loc)
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