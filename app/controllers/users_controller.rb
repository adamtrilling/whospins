class UsersController < ApplicationController
  def current
    if (current_user)
      @user_data = {
        :id => current_user.id,
        :location => current_user.location.try(:id)
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