class User < ActiveRecord::Base
  has_and_belongs_to_many :locations

  before_save :set_location_names

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
    end
  end

  def set_location_names
    # if the location changed, we need to store the location 
    # names in a hash so that we can rebuild the locations 
    # table without losing user data
    self.location_names = {}
    locations.each do |l|
      self.location_names[l.category] = l.name
    end
  end
end
