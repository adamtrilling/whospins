LOCATION_CATEGORIES = ['country', 'state', 'county', 'city'];

function updateLocationSelect(category) {
  clear_categories = LOCATION_CATEGORIES.slice(LOCATION_CATEGORIES.indexOf(category) + 1);

  // clear out the relevant options and add a placeholder
  $.each(clear_categories, function(i, cat) {
    $('select#' + cat).empty();
  });

  // get the children of the proper category
  request = $.ajax({
    url: "/locations/children/" + $('select#' + category).val() + ".json",
    dataType: "json"
  });

  request.done(function(opts) {
    // add the new options
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
      $('<option>').val('').appendTo('select#' + cat);

      if (response.location[cat]) {
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
$('#location-form select').change(function(event) {
  if (/^\d+$/.test(event.target.value)) {
    updateLocationSelect(this.id);
  }
});

// handle form submission
$('#location-form').submit(function(event) {
  event.preventDefault();

  var $form = $(this),
      country = $form.find('select#country').val(),
      state = $form.find('select#state').val(),
      county = $form.find('select#county').val(),
      city = $form.find('select#city').val(),
      url = $form.attr('action');

  request = $.ajax(url, { 
    type: 'PUT',
    data: {
      location: {
        country: country,
        state: state,
        county: county,
        city: city
      }
    }
  });

  request.done(function(result) {
    console.log(result);
    if (result['status'] == "OK") {
      $form.find('#location-save').addClass('btn-success');
    }
    else {
      $form.find('#location-save').addClass('btn-danger');
      $('#location-save-status').html(result['status']);
    }
  });
  return false;
});