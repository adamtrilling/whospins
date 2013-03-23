class LocationsController < ApplicationController
  caches_page :index

  def index
    @locations = Location.where(:category => 'state').where(:parent_id => Location.supported_country_ids.map(&:id))
  end

  def children
    @locations = Location.where(:parent_id => params[:id]).group_by(&:category)
  end
end