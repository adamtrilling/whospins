json.type "FeatureCollection"
json.features @locations do |json, loc|
  json.type 'Feature'
  json.id loc.id
  json.properties loc, :display_name, :num_users, :percent_rank
  json.geometry do |json|
    json.type 'MultiPolygon'
    json.coordinates loc.to_a
  end
end