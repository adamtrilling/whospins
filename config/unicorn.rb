worker_processes 4
working_directory "/var/www/whospins/current"
listen "/var/www/whospins/shared/run/unicorn.sock"
pid "/var/www/whospins/shared/run/unicorn.pid"

# supposedly this helps with ruby 2.0
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end