Spinmap.ApplicationView = Ember.View.extend({
  didInsertElement: function() {
    var map = L.map('map');
    var layer = L.tileLayer('/tiles/{z}/{x}/{y}.png');
    map.addLayer(layer).setView(new L.LatLng(38, -95), 1);
  }
});
