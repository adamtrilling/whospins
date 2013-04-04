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
    clear_categories = ['state', 'county', 'city'];
  } else if (category == 'state') {
    clear_categories = ['county', 'city'];
  }

  // get the children of the proper category
  request = $.ajax({
    url: "/locations/children/" + $('select#' + category).val() + ".json",
    dataType: "json"
  });

  request.done(function(opts) {
    // clear out the relevant options
    $.each(clear_categories, function(i, cat) {
      $('select#' + cat).empty();
    });

    // then add the new ones
    for (var cat in opts) {
      $('<option>').val('').appendTo('select#' + cat);
      $.each(opts[cat], function(index, value) {
        opt = $('<option>').val(value["id"]).text(value["name"])

        if (value["id"] == user_location) {
          opt.attr('selected', 'selected');
        }

        opt.appendTo('select#' + cat);
      });
    }
  });
}

// get user info
var user_location;
$.ajax({
  url: "/users/current.json",
  dataType: 'json',
  success: function(response) {
    user_location = response.location;
  },
});

// set up the map
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

// attach event handlers to the location selectors
$('#location-form select').change(function() {
  updateLocationSelect(this.id);
});