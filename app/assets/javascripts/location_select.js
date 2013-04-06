LOCATION_CATEGORIES = ['country', 'state', 'county', 'city'];

function updateLocationSelect(category) {
  clear_categories = LOCATION_CATEGORIES.slice(LOCATION_CATEGORIES.indexOf(category) + 1);

  // get the children of the proper category
  request = $.ajax({
    url: "/locations/children/" + $('select#' + category).val() + ".json",
    dataType: "json"
  });

  request.done(function(opts) {
    // clear out the relevant options
    $.each(clear_categories, function(i, cat) {
      console.log("clearing " + cat);
      $('select#' + cat).empty();
    });

    // then add the new ones
    for (var cat in opts) {
      $('<option>').val('').appendTo('select#' + cat);
      $.each(opts[cat], function(index, value) {
        opt = $('<option>').val(value["id"]).text(value["name"])
        opt.appendTo('select#' + cat);
      });
    }
  });
}

// get user info
$.ajax({
  url: "/users/current.json",
  dataType: 'json',
  success: function(response) {
    // populate the selects with the user's info, except country,
    // which was populated by rails
    $.each(LOCATION_CATEGORIES, function(i, cat) {
      if (response.location[cat]) {
        console.log("" + cat + " = " + response.location[cat]);

        // get the children for the next category, if there is one
        next_cat = LOCATION_CATEGORIES[i + 1]
        if (next_cat !== undefined) {
          request = $.ajax({
            url: "/locations/children/" + response.location[cat] + ".json",
            dataType: "json"
          });

          request.done(function(opts) {
            // rewrite any selects for which we get data
            for (var select in opts) {
              console.log("clearing " + select);
              $('select#' + select).empty();

              $('<option>').val('').appendTo('select#' + select);
              $.each(opts[select], function(index, value) {
                opt = $('<option>').val(value["id"]).text(value["name"])

                // test for whether to automatically select
                if (value["id"] == response.location[select]) {
                  opt.attr('selected', 'selected');
                }

                opt.appendTo('select#' + select);
              });
            }
          });
        }
      }
    });
  },
});

// attach event handlers to the location selectors
$('#location-form select').change(function() {
  updateLocationSelect(this.id);
});