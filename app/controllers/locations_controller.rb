class LocationsController < ApplicationController
  caches_page :index

  def index
    supported_countres = Location.where("name IN ('United States', 'Canada')")

    @locations = Location.where(:category => 'state').where(:parent_id => supported_countres.map(&:id))
  end
end