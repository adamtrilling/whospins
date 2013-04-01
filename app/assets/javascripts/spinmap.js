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
    opacity: 0.5,
    color: 'white',
    dashArray: '3',
    fillOpacity: 0.7
  };
}

/* set up the map */
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
    geojsonLayer = L.geoJson(response, {style: style}).addTo(map);
  },
});

/* attach event handlers to the location selectors */
$('select#country').change(function() {
  console.log("changed country to " + $('select#country').val());
  request = $.ajax({
    url: "/locations/children/" + $('select#country').val() + ".json",
    dataType: "json"
  });

  request.done(function(opts) {
    // clear out the states
    $('select#state').empty();

    // then add the new ones
    $.each(opts["state"], function(index, value) {
      console.log(value);
      $('<option>').val(value["id"]).text(value["name"]).appendTo('select#state');
    });
  });
});