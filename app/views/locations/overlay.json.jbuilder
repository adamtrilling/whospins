json.type "FeatureCollection"
json.features @locations do |json, loc|
  json.type 'Feature'
  json.id loc.id
  json.properties do |json|
    json.display_name loc.display_name
    json.num_users loc.users.size
    json.percentile loc.percent_rank
    json.users loc.users do |json, user|
      json.name user.uid
    end
  end
  json.geometry do |json|
    json.type 'MultiPolygon'
    json.coordinates loc.to_a
  end
end