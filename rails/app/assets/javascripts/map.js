function getColor(n) {
  return n > 0.9   ? '#88419D' :
         n > 0.5   ? '#8C96C6' :
         n > 0.25  ? '#B3CDE3' :
                     '#EDF8FB';
}

function style(feature) {
  return {
    fillColor: getColor(feature.properties.percentile),
    weight: 2,
    opacity: 1,
    color: 'white',
    dashArray: '',
    fillOpacity: 0.7
  };
}

function highlightFeature(e) {
  var layer = e.target;

  layer.setStyle({
    weight: 5,
    color: '#666',
    dashArray: '',
    fillOpacity: 0.7
  });

  if (!L.Browser.ie && !L.Browser.opera) {
    layer.bringToFront();
  }

  info.update(layer.feature.properties);
}

function resetHighlight(e) {
  geojsonLayer.resetStyle(e.target);
  info.update();
}

function zoomToFeature(e) {
  map.fitBounds(e.target.getBounds());

  // update the sidebar with the list of users
  props = e.target.feature.properties;

  html = "<b>" + props.display_name + "</b><br/>"
  for (var u in props.users) {
    html = html + '<br />';
    for (var p in props.users[u].profiles) {
      var profile = props.users[u].profiles[p];
      html = html + '<a href="' + profile.profile_url + '" target="_blank">';
      html = html + '<img src="/assets/' + profile.provider + '_24.png"/>';
      html = html + '</a>';
    }
    
    html = html + props.users[u].name;
  }
  $('#userlist').html(html);

  // if the feature was a country or a state, load 
  // the overlay for the feature
  if (props.category == 'country' || props.category == 'state') {
    overlayID = e.target.feature.id;
    getOverlay();
  }
}

function onEachFeature(feature, layer) {
  layer.on({
    mouseover: highlightFeature,
    mouseout: resetHighlight,
    click: zoomToFeature
  });
}

function getOverlay() {
  // remove the existing layer, if any
  if (geojsonLayer && map.hasLayer(geojsonLayer)) {
    map.removeLayer(geojsonLayer);
  }

  // grab the geojson layer
  $.ajax({
    type: "GET",
    url: "/locations/overlay/" + overlayID + ".json",
    dataType: 'json',
    async: false,
    success: function(response) {
      geojsonLayer = L.geoJson(response, {
        style: style,
        onEachFeature: onEachFeature
      });

      map.addLayer(geojsonLayer);
    },
  });
}

// set up the map
var map = L.map('map', {
  minZoom: 3,
  maxZoom: 8,
  maxBounds: [[-90, -180], [90, 180]]
});
var tileLayer = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpeg', {
  attribution: 'Tiles by <a href="http://www.mapquest.com/">MapQuest</a> &mdash; Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
  subdomains: '1234'
});
map.addLayer(tileLayer).setView(new L.LatLng(38, -95), 3);

var geojsonLayer = null;
var overlayID = '0';

getOverlay();

// info box
var info = L.control();

info.onAdd = function (map) {
  this._div = L.DomUtil.create('div', 'info'); // create a div with a class "info"
  this.update();
  return this._div;
};

// method that we will use to update the control based on feature properties passed
info.update = function (props) {
  var html = "";

  if (props) {
    html = '<b>' + props.display_name;

    if (props.num_users > 0) {
      html = html + '</b><br />' + props.num_users + ' spinner';
      if (props.num_users > 1){
        html = html + 's';
      }
    }
  }
  else {
    html = 'Click on a state or county';
  }

  this._div.innerHTML = (html);
};

info.addTo(map);
