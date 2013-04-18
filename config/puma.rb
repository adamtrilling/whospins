pidfile "/var/www/whospins/current/tmp/puma.pid"
state_path "/var/www/whospins/shared/sockets/puma.state"
bind 'unix:///var/www/whospins/shared/sockets/puma.sock'
activate_control_app