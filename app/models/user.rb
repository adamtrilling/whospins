class User < ActiveRecord::Base
  belongs_to :location

  # handle changes to location
  before_save :check_location_update

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
    end
  end

  def check_location_update
    # if the location changed, we need to:
    # 1) store the location names in a hash so that we can rebuild
    #    the locations table without losing user data
    # 2) increment and decrement the num_users cols in Location
    if (self.location_id_changed?)
      unless (self.location_id_was.nil?)
        Location.find(self.location_id_was).decrement_users!
      end
      new_location = Location.find(self.location_id)
      new_location.increment_users!

      location_names = {new_location.category => new_location.name}
      # iterate up the tree, populating names as we go
      location_parent = Location.find_by_id(new_location.parent_id)
      while (!location_parent.nil?)
        location_names[location_parent.category] = location_parent.name
        location_parent = Location.find_by_id(location_parent.parent_id)
      end
      self.location_names = location_names
    end
  end
end
