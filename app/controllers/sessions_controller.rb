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
          if (@auth.user.nil?)
            # add the identity to an existing user
            @auth.user = current_user
            @auth.save
          else
            # if the auth belongs to a user other than the logged-in user,
            # log in as that user and destroy the current user
            current_user.authorizations.each do |a|
              a.update_attributes(user_id: @auth.user.id)
            end
            current_user.destroy
            session[:user_id] = @auth.user.id
          end

          # expire any affected overlays.  since this action doesn't
          # change location user counts, we can just expire the overlays
          # that the user actually appears in.
          current_user.locations.each do |l|
            Rails.logger.info("Expiring overlay #{l.id}")
            FileUtils.rm_f(
              File.join(
                Whospins::Application.config.action_controller.page_cache_directory, 
                'locations', 'overlay', "#{l.id}.json"
              )
            )
            Rails.logger.info("Expiring states overlay")
            FileUtils.rm_f(
              File.join(
                Whospins::Application.config.action_controller.page_cache_directory, 
                'locations', 'overlay', "state.json"
              )
            )
          end

          redirect_to root_url, notice: "Added #{auth['provider']} account"
        end
      else
        unless (@auth.user)
          @auth.user = User.create
          # @auth failed validation before because there was no user
          @auth.save
        end

        session[:user_id] = @auth.user.id
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
