namespace :dev do
  desc "create a bunch of users with random locations"
  task :random_users => :environment do

    locations = Location.find_by_sql("select cities.*
  from locations countries,
       locations states,
       locations counties,
       locations cities
 where countries.category = 'country' and countries.id = states.parent_id
   and states.category = 'state' and states.id = counties.parent_id
   and counties.category = 'county' and counties.id = cities.parent_id
   and cities.category = 'city'
   and countries.name IN ('United States')
order by random()")

    1000.times do |i|
      print "user #{i}..."
      u = User.create(:name => "User#{i}")
      u.location = locations[i]
      u.save
      puts "done"
    end
  end
end