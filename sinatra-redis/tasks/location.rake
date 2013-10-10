require 'fileutils'
require 'redis'

DATA_DIR = File.dirname(__FILE__) + "/../data"

class Array
  def to_redis
    self.join(':')
  end
end

namespace :location do
  desc "Load Geonames data"
  task :load_geonames do
    redis = Redis.new

    FileUtils.mkdir_p DATA_DIR

    # download the whole geonames file
    unless (File.file?(File.join(DATA_DIR, 'allCountries.txt')))
      curl_cmd = "curl -L -o #{DATA_DIR}/allCountries.zip http://download.geonames.org/export/dump/allCountries.zip"
      unzip_cmd = "unzip -d #{DATA_DIR}/ #{DATA_DIR}/allCountries.zip"
      system curl_cmd
      system unzip_cmd
    end

    # allCountries.txt is a HUGE tsv
    File.open("#{DATA_DIR}/allCountries.txt", "r:UTF-8").each do |record|
      attrs = record.force_encoding('ISO-8859-1').encode('UTF-8').split("\t")

      # we only want places and administrative divisions
      next unless ([
        'ADM1', 'ADM2', 'ADM3', 'ADM4', 'ADM5',
        'PCL', 'PCLD', 'PCLH', 'PCLI', 'PCLIX', 'PCLS', 'TERR',
        'PPL', 'PPLA', 'PPLA2', 'PPLA3', 'PPLA4', 'PPLC', 
        'PPLG', 'PPLL', 'PPLR', 'PPLS'
      ].include?(attrs[7]))

      # build the key
      key = ['locations']
      key << attrs[8] # country

      # PCL* is top-level, so they don't get any admin divisions
      unless (attrs[7] =~ /^PCL.?$/)
        (10..13).each {|i| key << attrs[i] unless attrs[i].empty? } # admin divisions
        key << attrs[0] if attrs[6] == 'P' # geonames id, for uniqueness
      end

      # insert the data into redis
      puts "(#{key.join(':')}) - #{attrs[1]}"
      redis.set((key + ['name']).to_redis, attrs[1])
      redis.set((key + ['class']).to_redis, "#{attrs[6]}.#{attrs[7]}")
      redis.sadd((key.slice(0..-2) + ['children']).to_redis, key.to_redis)
    end
  end
end