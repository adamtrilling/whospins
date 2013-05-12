class MultipleOmniauthProviders < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.references :user
      t.string :provider
      t.string :uid
      t.hstore :info
    end

    add_index :authorizations, :user_id
    add_index :authorizations, :provider
    add_index :authorizations, :uid
    execute "CREATE INDEX authorizations_info_index ON authorizations USING gin(info)"

    # move info over from the users table
    User.all.each do |u|
      Authorization.create(
        user_id: u.id,
        provider: u.provider,
        uid: u.uid,
        info: {
          'name' => u.uid,
          'profile_url' => "http://www.ravelry.com/people/#{u.uid}"
        }
      )
    end

    remove_column :users, :name
    remove_column :users, :provider
    remove_column :users, :uid
  end
end
