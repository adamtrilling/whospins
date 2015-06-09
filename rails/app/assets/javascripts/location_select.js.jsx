var LocationFormBlankState = React.createClass({
  render: function() {
    return  (
<p>        
  <a href="#loginModal" data-toggle="modal">Log In</a> to add your location
</p>
    )
  }
});

var LocationForm = React.createClass({
  fetchUserInfo: function() {
    $.ajax({
      url: '/users/current.json',
      dataType: 'json',
      cache: false,
      success: function(data) {
        this.setState({
          loggedIn: data.user_id != null,
          locations: data.locations
        });
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },

  handleLocationChanged: function(adm_level, new_location) {
    var newLocations = this.state.locations;
    newLocations[adm_level - 1] = new_location;
    for(var i = adm_level; i < 4; i++) {
      newLocations[i] = undefined;
    }
    this.setState({
      locations: newLocations
    });
  },
  
  getInitialState: function() {
    return {
      loggedIn: false,
      locations: []
    };
  },

  componentDidMount: function() {
    this.fetchUserInfo();
  },

  render: function() {
    if (this.state.loggedIn) {
      var selectedLocations = this.state.locations.map(
        function(location_id) {
        }
      );
      return (
  <form className="form-horizontal">
    <LocationSelect key="1" adm_level="1" selected={this.state.locations[0]} parent={0} onLocationChange={this.handleLocationChanged} />
    <LocationSelect key="2" adm_level="2" selected={this.state.locations[1]} parent={this.state.locations[0]} onLocationChange={this.handleLocationChanged} />
    <LocationSelect key="3" adm_level="3" selected={this.state.locations[2]} parent={this.state.locations[1]} onLocationChange={this.handleLocationChanged} />
    <LocationSelect key="4" adm_level="4" selected={this.state.locations[3]} parent={this.state.locations[2]} onLocationChange={this.handleLocationChanged} />
    <div className="control-group">
      <div className="controls">
        <input type="submit" className='btn' value="Save" data-loading-text="Saving..." data-saved-text="Saved!" />
      </div>
    </div>
  </form>
      )
    } else {
      return (<LocationFormBlankState />)
    }
  }
});

var LocationSelect = React.createClass({
  labelName: function() {
    if (this.props.adm_level == '1') {
      return 'Country';
    } else {
      return '';
    }
  },

  fetchOptions: function() {
    if (this.props.parent === undefined) {
      this.setState({
        options: []
      });
    } else {
      $.ajax({
        url: '/locations/children/' + this.props.parent + '.json',
        dataType: 'json',
        cache: false,
        success: function(data) {
          this.setState({
            options: data
          });
        }.bind(this),
        error: function(xhr, status, err) {
          console.error(this.props.url, status, err.toString());
        }.bind(this)
      });
    }
  },

  getInitialState: function() {
    return {
      options: []
    }
  },

  componentDidMount: function() {
    this.fetchOptions();
  },

  componentWillUpdate: function() {
    this.fetchOptions();
  },

  handleChange: function(event) {
    this.props.onLocationChange(this.props.adm_level, event.target.value);
  },

  render: function() {
    var options = $.map(this.state.options, function(opt) {
      return (
        <LocationOption key={opt.id} name={opt.name} value={opt.id} />
      )
    }.bind(this));

    return (
      <div className="control-group">
        <label name={"adm_" + this.props.adm_level} className="control-label">{this.labelName()}</label>
        <div className="controls">
          <select name={"adm_" + this.props.adm_level} value={this.props.selected} onChange={this.handleChange}>
            <option value="" />
            {options}
          </select>
        </div>
      </div>
    )
  },
});

var LocationOption = React.createClass({
  render: function() {
    return ( 
      <option value={this.props.value}>{this.props.name}</option>
    )
  }
});

React.render(
  <LocationForm />,
  document.getElementById('location')
);
