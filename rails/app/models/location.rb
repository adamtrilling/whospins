class Location < ActiveRecord::Base
  has_and_belongs_to_many :users

  # the parents hash in the database is pretty useless, 
  # since it just returns ids as text, so replace it with
  # a real accessor.
  # TODO: this will fail if ANY of the parents isn't found.
  #       if one parent is missing, it should return the rest.
  def parents
    begin
      Location.find(self.read_attribute(:parents).keys)
    rescue ActiveRecord::RecordNotFound
      []
    end
  end

  def parent
    Location.find(parent_id)
  end

  def country
    # recurse up the tree until we get a country
    current_loc = self
    while (current_loc.category != 'country')
      current_loc = current_loc.parents
    end

    current_loc
  end

  def display_name
    if (category == 'country')
      name
    elsif (category == 'state' || category == 'city')
      "#{name}, #{parents.first.name}"
    elsif (category == 'county')
      "#{name} County, #{parents.first.name}"
    end
  end

  scope :supported_country_ids, -> { 
    select('id').where(:category => 'country', :name => ['United States', 'Canada'])
  }

  scope :supported_countries, -> {
    where(:category => 'country', :id => supported_country_ids)
  }

  # converts the area to an array of points.  this makes it far simpler
  # for jbuilder to build geojson of multipolygons.
  def to_a
    return [] if area.nil?

    # stolen from rgeo-geojson
    point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y] }
    area.map { |poly_| 
      [poly_.exterior_ring.points.map(&point_encoder_)] + 
      poly_.interior_rings.map{ |r_| r_.points.map(&point_encoder_) } 
    }
  end
end
