class EnforceUserLocationUniqueness < ActiveRecord::Migration
  def change
    User.all.each do |u|
      puts "user #{u.id} #{u.uid}"
      ids = u.location_ids.uniq
      u.connection.execute("DELETE FROM locations_users WHERE user_id = #{u.id}")
      ids.each do |l|
        u.connection.execute("INSERT INTO locations_users(user_id, location_id) VALUES(#{u.id}, #{l})")
      end
    end

    User.set_location_numbers

    add_index :locations_users, [:location_id, :user_id], :unique => true
  end
end
