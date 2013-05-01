class User < ActiveRecord::Base
  attr_accessor :old_location_ids

  has_and_belongs_to_many :locations

  before_save :set_location_names
  after_save :update_location_numbers

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

  def update_location_numbers
    # cache the location numbers and percentile.  it saves a 
    # TON of time in generating overlays.
    User.transaction do 
      connection.execute("
UPDATE locations SET num_users = num_users + 1 
 WHERE id IN (#{location_ids.join(',')})")
      connection.execute("
UPDATE locations SET num_users = num_users - 1 
 WHERE id IN (#{self.old_location_ids.join(',')})")

      # it's theoretically possible to both get and update
      # the percentiles in one query, but said query is a 
      # real mess.
      location_ids.each do |id|
        percentiles = connection.select_all("
SELECT id, percent_rank() OVER (ORDER BY num_users) 
  FROM locations
 WHERE locations.parents ? '#{id}'
   AND (num_users > 0)")

        percentiles.each do |p|
          connection.execute("
UPDATE locations 
   SET percentile = #{p['percent_rank']} 
 WHERE id = #{p['id']}")
        end
      end
    end
  end

  def self.set_location_numbers!
    # cache the location numbers.  it saves a TON of time
    # in generating overlays.
    User.transaction do
      connection.execute("
UPDATE locations SET num_users = 0
 WHERE id NOT IN (SELECT location_id FROM locations_users)")
      connection.execute("
UPDATE locations SET num_users = subquery.num
  FROM (SELECT location_id, count(user_id) as num
          FROM locations_users
      GROUP BY location_id) AS subquery
 WHERE locations.id = subquery.location_id")

      Location.where("num_users > 0").pluck(:id).each do |id|
        percentiles = connection.select_all("
SELECT id, percent_rank() OVER (ORDER BY num_users) 
  FROM locations
 WHERE locations.parents ? '#{id}'
   AND (num_users > 0)")

        percentiles.each do |p|
          connection.execute("
UPDATE locations 
   SET percentile = #{p['percent_rank']} 
 WHERE id = #{p['id']}")
        end
      end
    end
  end
end
