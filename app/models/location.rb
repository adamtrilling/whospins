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
end