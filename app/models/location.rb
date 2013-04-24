class Location < ActiveRecord::Base
  has_and_belongs_to_many :users

  # we don't need a full tree, so just define the necessary accessors
  def parents
    begin
      Location.find(self.parents.keys)
    rescue ActiveRecord::RecordNotFound
      nil
    end
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
      "#{name}, #{parent.name}"
    elsif (category == 'county')
      "#{name} County, #{parent.name}"
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