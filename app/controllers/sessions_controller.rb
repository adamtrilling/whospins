class SessionsController < ApplicationController

  def new
    redirect_to '/auth/ravelry'
  end

  def create
    Rails.logger.info("*** in create action")
    begin
      auth = request.env["omniauth.auth"]
      Rails.logger.info("*** authenticating with #{auth}")
      user = User.where(:provider => auth['provider'], 
                        :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)
      Rails.logger.info("*** user = #{user.id}")
      session[:user_id] = user.id
      redirect_to root_url, :notice => 'Signed in!'
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
