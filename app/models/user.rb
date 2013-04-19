class User < ActiveRecord::Base
  has_and_belongs_to_many :locations

  before_save :set_location_names
  after_save :set_location_numbers

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

  def set_location_numbers
    # cache the location numbers.  it saves a TON of time
    # in generating overlays.
    User.transaction do 
      connection.execute("
UPDATE locations SET num_users = 0
 WHERE location_id NOT IN (SELECT location_id FROM locations_users)")
      connection.execute("
UPDATE locations SET num_users = subquery.num 
  FROM (SELECT location_id, count(user_id) as num
          FROM locations_users 
      GROUP BY location_id) AS subquery
 WHERE locations.id = subquery.location_id")
    end
  end

end
