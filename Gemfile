source 'https://rubygems.org'

# framework
gem 'rails', '4.0.0.beta1'
gem 'actionpack-page_caching'
gem 'passenger', '4.0.0.rc6'

# database
gem 'pg'
gem 'activerecord-postgis-adapter', :github => 'dazuma/activerecord-postgis-adapter'
# gem 'activerecord-postgis-adapter', :path => '../activerecord-postgis-adapter'

# gis
# gem 'ffi-geos'
gem 'rgeo-shapefile'
gem 'simpler-tiles', :require => 'simpler_tiles', :github => 'propublica/simpler-tiles'

# front end
group :assets do
  gem 'sass-rails',   '~> 4.0.0.beta1'
  gem 'coffee-rails', '~> 4.0.0.beta1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'haml'
gem 'haml-rails'
gem 'jbuilder'
gem 'jquery-rails'
gem 'therubyracer'

# authentication
gem 'omniauth'
gem 'omniauth-ravelry'

# other
gem 'mechanize'

# debugging
gem 'quiet_assets'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'  

  # deployment
  gem 'capistrano'
end
