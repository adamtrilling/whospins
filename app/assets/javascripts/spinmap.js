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

function updateLocationSelect(category) {
  // this logic needs to change if the location hierarchy improves
  if (category == 'country') {
    request = $.ajax({
      url: "/locations/children/" + $('select#country').val() + ".json",
      dataType: "json"
    });

    request.done(function(opts) {
      // clear out everything
      $('select#state').empty();
      $('select#county').empty();
      $('select#city').empty();

      // then add the new ones
      $('<option>').val('').appendTo('select#state');
      $.each(opts["state"], function(index, value) {
        $('<option>').val(value["id"]).text(value["name"]).appendTo('select#state');
      });
    });
  }
  else if (category == 'state') {
    request = $.ajax({
      url: "/locations/children/" + $('select#state').val() + ".json",
      dataType: "json"
    });

    request.done(function(opts) {
      // clear out the cities and counties
      $('select#county').empty();
      $('select#city').empty();

      // then add the new ones
      if (opts["county"]) {
        $('<option>').val('').appendTo('select#county');
        $.each(opts["county"], function(index, value) {
          $('<option>').val(value["id"]).text(value["name"]).appendTo('select#county');
        });
      }

      if (opts["city"]) {
        $('<option>').val('').appendTo('select#city');
        $.each(opts["city"], function(index, value) {
          $('<option>').val(value["id"]).text(value["name"]).appendTo('select#city');
        });
      }
    });
  }
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

updateLocationSelect('country');

/* attach event handlers to the location selectors */
$('#location-form select').change(function() {
  updateLocationSelect(this.id);
});