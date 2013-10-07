environment 'production'

root = '/var/www/whospins'
shared = "#{root}/shared"

bind "unix://#{shared}/sockets/puma.sock"
pidfile "#{shared}/sockets/puma.pid"
state_path "#{shared}/sockets/puma.state"

threads 0,16

activate_control_app