json.type "FeatureCollection"
json.features @locations do |json, loc|
  json.type 'Feature'
  json.id loc.id
  json.properties loc, :name, :percent_rank
  json.geometry do |json|
    json.type 'MultiPolygon'
    json.coordinates loc.to_a
  end
end