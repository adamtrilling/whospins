class LocationsController < ApplicationController
  caches_page :index

  def index
    @locations = Location.where(:category => 'state').where(:parent_id => Location.supported_country_ids.map(&:id))
  end

  def children
    @locations = Location.where(:parent_id => params[:id]).select(:id, :name, :category).group_by(&:category)

    # no reason to use jbuilder when to_json works fine
    respond_to do |format|
      format.json do        
        render :json @locations.to_json
      end
    end
  end
end