json.type "FeatureCollection"
json.features @locations do |json, loc|
  json.type 'Feature'
  json.id loc.id
  json.properties do |json|
    json.category loc.category
    json.display_name loc.display_name
    json.num_users loc.users.size
    json.percentile loc.percentile
    json.users loc.users.sort_by(&:sort_name) do |json, user|
      json.name user.name
      json.profiles user.authorizations.sort_by(&:provider) do |json, auth|
        json.provider auth.provider
        json.profile_url auth.profile_url
      end
    end
  end
  json.geometry do |json|
    json.type 'MultiPolygon'
    json.coordinates loc.to_a
  end
end