class UsersController < ApplicationController
  # this is a debug page for special people
  def index
    unless (current_user && 
            current_user.authorizations.where(provider: 'ravelry').first &&
            ['BobbyTables', 'breyerchic04'].include?(current_user.authorizations.where(provider: 'ravelry').first.uid))
      redirect_to root_url
    end

    page = params[:page] || 0

    @user_count = User.count

    @users = User.paginate(:page => params[:page], :per_page => 50).order('id DESC')
  end

  def count
    render :text => "Number of users: #{User.all.count}"
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