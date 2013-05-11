class MultipleOmniauthProviders < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.references :user
      t.string :provider
      t.string :uid
    end

    add_index :authorizations, :user_id
    add_index :authorizations, :provider
    add_index :authorizations, :uid

    # move info over from the users table
    User.all.each do |u|
      Authorization.create(
        user_id: u.id,
        provider: u.provider,
        uid: u.uid
      )

      u.update_attributes(name: u.uid)
    end

    remove_column :users, :provider
    remove_column :users, :uid
  end
end
