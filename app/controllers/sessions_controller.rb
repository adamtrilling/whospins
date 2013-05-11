class SessionsController < ApplicationController

  def new
    redirect_to "/auth/#{params[:provider]}"
  end

  def create
    begin
      auth = request.env["omniauth.auth"]

      @auth = Authorization.find_with_omniauth(auth)

      if (@auth.nil?)
        @auth = Authorization.create_with_omniauth(auth)
      end

      if user_signed_in?
        if (@auth.user == current_user)
          # if user is trying to add an identity that is already added
          redirect_to root_url, notice: 'That account is already linked!'
        else
          # add the identity to an existing user
          @auth.user = current_user
          @auth.save
          redirect_to root_url, notice: "Added #{auth['provider']} account"
        end
      else
        session[:user_id] = @auth.user
        redirect_to root_url, :notice => 'Signed in!'
      end
    rescue Exception => e
      Rails.logger.info("*** exception: #{e.to_s}\n#{e.backtrace.join("\n")}")
    end
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
