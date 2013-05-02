namespace :tile do
  desc "generate all tiles"
  task :generate => :environment do 
    if (Rails.env == 'production')
      host = 'whospins.com'
    else
      host = 'whospins.dev'
    end

    agent = Mechanize.new

    (3..11).each do |z|
      (0..(2**z) - 1).each do |x|
        (0..(2**z) - 1).each do |y|
          puts "generating #{z} (#{x}, #{y})"
          FileUtils.rm_f(
            File.join(
              Whospins::Application.config.action_controller.page_cache_directory, 
              'tiles', "#{z}", "#{x}", "#{y}.png"
            )
          )
          agent.get("http://#{host}/tiles/#{z}/#{x}/#{y}.png")
        end
      end
    end
  end
end

namespace :overlay do
  desc "generate all overlays"
  task :generate => :environment do
    if (Rails.env == 'production')
      host = 'whospins.com'
    else
      host = 'whospins.dev'
    end

    puts "removing existing overlays"
    FileUtils.rm_rf(
      File.join(
        Whospins::Application.config.action_controller.page_cache_directory, 
          'locations', 'overlay'
      )
    )

    agent = Mechanize.new

    Location.where(category: 'state').where("num_users > 0").each do |l|
      puts "generating (#{l.id}) #{l.name}"
      agent.get("http://#{host}/locations/overlay/#{l.id}.json")
    end
  end
end