set :stage, :production

set :application, 'example.com'
set :deploy_to, -> { "/srv/www/#{fetch(:application)}" }

# Simple Role Syntax
# ==================
#role :app, %w{deploy@example.com}
#role :web, %w{deploy@example.com}
#role :db,  %w{deploy@example.com}

# Extended Server Syntax
# ======================
server '{{SERVER_IP}}', user: 'root', roles: %w{web app db}

# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
set :ssh_options, {
  keys: %w(../vagrant-digitalocean/id_rsa_vagrant),
  forward_agent: true,
  user: 'root'
# auth_methods: %w(password)
}

fetch(:default_env).merge!(wp_env: :staging)

