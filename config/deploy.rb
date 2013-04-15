set :application, "whospins"

set :scm, :git 
set :repository,  "git@github.com:adamtrilling/whospins.git"
set :branch, 'master'
set :deploy_via, :remote_cache

set :user, 'apps'
set :ssh_options, { :forward_agent => true }
set :use_sudo, false

set :deploy_to, "/var/www/#{application}"
set :shared_children, shared_children + %w(config)

role :web, "www.whospins.com"
role :app, "www.whospins.com"
role :db,  "www.whospins.com", :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/keys.yml #{release_path}/config/keys.yml"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'