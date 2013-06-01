class User < ActiveRecord::Base
  attr_accessor :old_location_ids

  has_many :authorizations
  has_and_belongs_to_many :locations

  before_save :set_location_names
  after_save :update_location_numbers

  def self.create_with_omniauth(auth)
    create(name: auth['name'])
  end

  def set_location_names
    # if the location changed, we need to store the location 
    # names in a hash so that we can rebuild the locations 
    # table without losing user data
    self.location_names = locations.inject ({}) do |locs, loc|
      locs[loc.category] = loc.name
      locs
    end
  end

  def update_location_numbers
    # cache the location numbers and percentile.  it saves a 
    # TON of time in generating overlays.
    User.transaction do
      if (location_ids.size > 0)
        connection.execute("
UPDATE locations SET num_users = num_users + 1 
 WHERE id IN (#{location_ids.join(',')})")
      end

      if (self.old_location_ids && self.old_location_ids.size > 0)
        connection.execute("
UPDATE locations SET num_users = num_users - 1 
 WHERE id IN (#{self.old_location_ids.join(',')})")
      end

      # it's theoretically possible to both get and update
      # the percentiles in one query, but said query is a 
      # real mess.
      location_ids.concat(self.old_location_ids.nil? ? [] : self.old_location_ids).each do |id|
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

  def name
    # Facebook and Google both provide real names, so use ravelry if possible
    authorizations.each do |auth|
      if (auth.provider == 'ravelry')
        return auth.info["name"]
      end
    end

    return authorizations.first.info["name"]
  end

  def sort_name
    name.downcase
  end
end
