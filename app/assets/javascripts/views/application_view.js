Spinmap.ApplicationView = Ember.View.extend({
  didInsertElement: function() {
    var map = L.map('map', {
      minZoom: 3,
      maxZoom: 11,
      maxBounds: [[-90, -180], [90, 180]]
    });
    var layer = L.tileLayer('/tiles/{z}/{x}/{y}.png');
    map.addLayer(layer).setView(new L.LatLng(38, -95), 3);

    // grab the geojson layer
    $.ajax({
      type: "GET",
      url: "/locations.json",
      dataType: 'json',
      success: function(response) {
        console.log("adding geojson layer");
        geojsonLayer = L.geoJson(response).addTo(map);
      },
    });
  }
});
