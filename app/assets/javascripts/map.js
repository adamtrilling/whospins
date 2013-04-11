function getColor(n) {
  return n > 0.9   ? '#88419D' :
         n > 0.5   ? '#8C96C6' :
         n > 0.25  ? '#B3CDE3' :
                     '#EDF8FB';
}

function style(feature) {
  return {
    fillColor: getColor(feature.properties.percent_rank),
    weight: 2,
    opacity: 1,
    color: 'white',
    dashArray: '3',
    fillOpacity: 0.7
  };
}

function loadOverlay() {
  if (map.getZoom() >= 6) {
    if (map.hasLayer(geojsonLayers['state'])) {
      map.removeLayer(geojsonLayers['state']);
    }
    if (!map.hasLayer(geojsonLayers['county'])) {
      map.addLayer(geojsonLayers['county']);
    }
  }
  else {
    if (map.hasLayer(geojsonLayers['county'])) {
      map.removeLayer(geojsonLayers['county']);
    }
    if (!map.hasLayer(geojsonLayers['state'])) {
      map.addLayer(geojsonLayers['state']);
    }
  }
}

// set up the map
var map = L.map('map', {
  minZoom: 3,
  maxZoom: 11,
  maxBounds: [[-90, -180], [90, 180]]
});
var layer = L.tileLayer('/tiles/{z}/{x}/{y}.png');
map.addLayer(layer).setView(new L.LatLng(38, -95), 3);

// load the geoJSON layers
var geojsonLayers = {
  state: null,
  county: null
};

$.each(geojsonLayers, function(key) {
  // grab the geojson layer
  $.ajax({
    type: "GET",
    url: "/locations/overlay/" + key + ".json",
    dataType: 'json',
    async: false,
    success: function(response) {
      geojsonLayers[key] = L.geoJson(response, {style: style});
    },
  });  
});

console.log(geojsonLayers);

loadOverlay();
map.on('zoomend', loadOverlay);