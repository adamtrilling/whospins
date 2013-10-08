require 'fileutils'
require 'redis'

DATA_DIR = File.dirname(__FILE__) + "/data"

namespace :location do
  desc "Load Geonames data"
  task :load_geonames do
    FileUtils.mkdir_p DATA_DIR
  end
end