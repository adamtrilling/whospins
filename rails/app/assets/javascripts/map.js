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
  var props = e.target.feature.properties;

  // if the feature was a country or a state, load 
  // the overlay for the feature
  if (props.category == 'country' || props.category == 'state') {
    getOverlay(e.target.feature.id);
  }
  getUsers(e.target.feature.id);
}

function onEachFeature(feature, layer) {
  layer.on({
    mouseover: highlightFeature,
    mouseout: resetHighlight,
    click: zoomToFeature
  });
}

function getOverlay(locationId) {
  // remove the existing layer, if any
  if (geojsonLayer && map.hasLayer(geojsonLayer)) {
    map.removeLayer(geojsonLayer);
  }

  // grab the geojson layer
  $.ajax({
    type: "GET",
    url: "/locations/overlay/" + locationId + ".json",
    dataType: 'json',
    success: function(response) {
      geojsonLayer = L.geoJson(response, {
        style: style,
        onEachFeature: onEachFeature
      });

      map.addLayer(geojsonLayer);
    },
  });
}

function getUsers(locationId) {
  $.ajax({
    type: "GET",
    url: "/locations/users/" + locationId + ".json",
    dataType: 'json',
    success: function(response) {
      console.log("getting users for " + locationId);
      // update the sidebar with the list of users
      var   html = "<b>" + response.display_name + "</b><br/>";
      var users = response.users;
      for (var u in users) {
        html = html + '<br />';
        for (var p in users[u].profiles) {
          var profile = users[u].profiles[p];
          html = html + '<a href="' + profile.profile_url + '" target="_blank">';
          html = html + '<img src="/assets/' + profile.provider + '_24.png"/>';
          html = html + '</a>';
        }

        html = html + users[u].name;
      }
      $('#userlist').html(html);
    },
  });
}

// set up the map
var map = L.map('map', {
  minZoom: 2,
  maxZoom: 8,
  maxBounds: [[-90, -180], [90, 180]]
});
var tileLayer = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/map/{z}/{x}/{y}.jpeg', {
  attribution: 'Tiles by <a href="http://www.mapquest.com/">MapQuest</a> &mdash; Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
  subdomains: '1234'
});
map.addLayer(tileLayer).setView(new L.LatLng(0, 0), 2);

var geojsonLayer = null;
getOverlay(0);

// info box
var info = L.control();

info.onAdd = function (map) {
  this._div = L.DomUtil.create('div', 'info'); 
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

// zoom to parent button
L.Control.EasyButtons = L.Control.extend({
    options: {
        position: 'topleft',
        title: '',
        intendedIcon: 'fa-circle-o'
    },

    onAdd: function () {
        var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control');

        this.link = L.DomUtil.create('a', 'leaflet-bar-part', container);
        this._addImage()
        this.link.href = '#';

        L.DomEvent.on(this.link, 'click', this._click, this);
        this.link.title = this.options.title;

        return container;
    },

    intendedFunction: function(){ alert('no function selected');},

    _click: function (e) {
        L.DomEvent.stopPropagation(e);
        L.DomEvent.preventDefault(e);
        this.intendedFunction();
        this.link.blur();
    },

    _addImage: function () {
        var extraClasses = this.options.intendedIcon.lastIndexOf('fa', 0) === 0 ? ' fa fa-lg' : ' glyphicon';

        var icon = L.DomUtil.create('i', this.options.intendedIcon + extraClasses, this.link);
        icon.id = this.options.id;
    }
});

L.easyButton = function( btnIcon , btnFunction , btnTitle , btnMap , btnId) {
  var newControl = new L.Control.EasyButtons();

  if (btnIcon) newControl.options.intendedIcon = btnIcon;
  if (btnId) newControl.options.id = btnId;

  if ( typeof btnFunction === 'function'){
    newControl.intendedFunction = btnFunction;
  }

  if (btnTitle) newControl.options.title = btnTitle;

  if ( btnMap === '' ){
    // skip auto addition
  } else if ( btnMap ) {
    btnMap.addControl(newControl);
  } else {
    map.addControl(newControl);
  }
  return newControl;
};

L.easyButton('some-icon', function() { 
  console.log("clicked");
  getOverlay(0); 
}, "Zoom to World", map);
