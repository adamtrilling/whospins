class Location < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :parent, class_name: 'Location'
  has_many :children, class_name: 'Location', foreign_key: 'parent_id'

  def country
    # recurse up the tree until we get a country
    current_loc = self
    while (current_loc.adm_level > 1)
      current_loc = current_loc.parent
    end

    current_loc
  end

  def display_name
    if (adm_level == 1)
      name
    else (category == 'state' || category == 'city')
      "#{name}, #{parent.name}"
    end
  end
end
