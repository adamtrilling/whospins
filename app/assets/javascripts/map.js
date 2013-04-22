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
    dashArray: '3',
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
}

function onEachFeature(feature, layer) {
  layer.on({
    mouseover: highlightFeature,
    mouseout: resetHighlight,
    click: zoomToFeature
  });
}

function getOverlay() {
  $.each(geojsonLayers, function(key) {
    // grab the geojson layer
    $.ajax({
      type: "GET",
      url: "/locations/overlay/" + key + ".json",
      dataType: 'json',
      async: false,
      success: function(response) {
        geojsonLayers[key] = L.geoJson(response, {
          style: style,
          onEachFeature: onEachFeature
        });
      },
    });  
  });
}

function loadOverlay() {
  if (map.getZoom() >= 6) {
    if (map.hasLayer(geojsonLayers['state'])) {
      map.removeLayer(geojsonLayers['state']);
    }
    if (!map.hasLayer(geojsonLayers['county'])) {
      map.addLayer(geojsonLayers['county']);
      geojsonLayer = geojsonLayers['county'];
    }
  }
  else {
    if (map.hasLayer(geojsonLayers['county'])) {
      map.removeLayer(geojsonLayers['county']);
    }
    if (!map.hasLayer(geojsonLayers['state'])) {
      map.addLayer(geojsonLayers['state']);
      geojsonLayer = geojsonLayers['state'];
    }
  }
}

function refreshOverlay() {
  if (map.getZoom() >= 6) {
    if (map.hasLayer(geojsonLayers['county'])) {
      map.removeLayer(geojsonLayers['county']);
    }
    map.addLayer(geojsonLayers['county']);
    geojsonLayer = geojsonLayers['county'];
  }
  else {
    if (map.hasLayer(geojsonLayers['state'])) {
      map.removeLayer(geojsonLayers['state']);
    }
    map.addLayer(geojsonLayers['state']);
    geojsonLayer = geojsonLayers['state'];
  }  
}

// set up the map
var map = L.map('map', {
  minZoom: 3,
  maxZoom: 11,
  maxBounds: [[-90, -180], [90, 180]]
});
var tileLayer = L.tileLayer('/tiles/{z}/{x}/{y}.png');
map.addLayer(tileLayer).setView(new L.LatLng(38, -95), 3);

// load the geoJSON layers
var geojsonLayers = {
  state: null,
  county: null
};
var geojsonLayer = null;

getOverlay();
loadOverlay();
map.on('zoomend', loadOverlay);

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
      html = html + '</b><br />' + props.num_users + ' spinners';
      for (var u in props.users) {
        html = html + '<br />' + props.users[u].name;
      }
    }
  }
  else {
    html = 'Hover over a state or county';
  }

  this._div.innerHTML = (html);
};

info.addTo(map);