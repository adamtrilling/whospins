class UsersController < ApplicationController
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