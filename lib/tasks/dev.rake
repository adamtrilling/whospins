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

      # walk up the tree
      current_loc = locations[i]
      while (!current_loc.nil?)
        u.locations << current_loc
        current_loc = current_loc.parent
      end

      u.save
      puts "done"
    end
  end
end