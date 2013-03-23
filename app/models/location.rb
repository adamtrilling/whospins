class Location < ActiveRecord::Base
  has_many :users

  # we don't need a full tree, so just define the necessary accessors
  def parent
    begin
      Location.find(self.parent_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  # when we update a user count, we need to do the same for parents
  ['increment', 'decrement'].each do |direction|
    define_method "#{direction}_users!" do
      current_loc = self
      while (!current_loc.nil?)
        current_loc.send("#{direction}!".to_sym, :num_users)
        current_loc = current_loc.parent
      end
    end
  end

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