module PagesHelper
  def current_user_country_id
    if (current_user && 
        current_user.locations.where(:category => 'country').first)
      current_user.locations.where(:category => 'country').first.id
    else
      nil
    end
  end
end
