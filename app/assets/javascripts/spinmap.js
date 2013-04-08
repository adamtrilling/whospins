function getColor(n) {
  return n > 50   ? '#EDF8FB' :
         n > 20   ? '#B3CDE3' :
         n > 10   ? '#8C96C6' :
                  '#EDF8FB';
}

function style(feature) {
  return {
    fillColor: getColor(feature.properties.num_users),
    weight: 2,
    opacity: 1,
    color: 'white',
    dashArray: '3',
    fillOpacity: 0.7
  };
}

function loadOverlay() {
  // remove the existing layer, if any
  if (geojsonLayer !== null) {
    map.removeLayer(geojsonLayer);
  }

  if (map.getZoom() >= 5) {
    url = "/locations/overlay/county.json";
  }
  else {
    url = "/locations/overlay/state.json";
  }

  // grab the geojson layer
  $.ajax({
    type: "GET",
    url: url,
    dataType: 'json',
    success: function(response) {
      geojsonLayer = L.geoJson(response, {style: style}).addTo(map);
    },
  });
}

// set up the map
var map = L.map('map', {
  minZoom: 3,
  maxZoom: 11,
  maxBounds: [[-90, -180], [90, 180]]
});
var layer = L.tileLayer('/tiles/{z}/{x}/{y}.png');
map.addLayer(layer).setView(new L.LatLng(38, -95), 3);

var geojsonLayer = null;
map.on({
  'load': loadOverlay,
  'zoomend': loadOverlay
});