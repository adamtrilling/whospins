namespace :dev do
  desc "create a bunch of users with random locations"
  task :random_users => :environment do 
    1000.times do |i|
      print "user #{i}..."
      u = User.create(:name => "User#{i}")
      u.location = Location.where(:category => 'county').order('random()').first
      u.save
      puts "done"
    end
  end
end