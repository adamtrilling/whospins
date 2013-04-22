namespace :tile do
  desc "generate all tiles"
  task :generate => :environment do 
    if (Rails.env == 'production')
      host = 'whospins.com'
    else
      host = 'whospins.dev'
    end

    puts "removing existing tiles"
    FileUtils.rm_rf(
      File.join(
        Whospins::Application.config.action_controller.page_cache_directory, 
          'tiles'
      )
    )

    agent = Mechanize.new

    (3..11).each do |z|
      (0..(2**z) - 1).each do |x|
        (0..(2**z) - 1).each do |y|
          puts "generating #{z} (#{x}, #{y})"
          agent.get("http://#{host}/tiles/#{z}/#{x}/#{y}.png")
        end
      end
    end
  end
end