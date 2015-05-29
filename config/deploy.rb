set :repo_url, '{{GIT_REPO}}'
set :subdir, "{{GIT_SUB_DIR}}" # relative path to project root in repo

# Branch options
# Prompts for the branch name (defaults to current branch)
#ask :branch, -> { `git rev-parse --abbrev-ref HEAD`.chomp }

# Hardcodes branch to always be master
# This could be overridden in a stage config file
set :branch, :master

# Use :debug for more verbose output when troubleshooting
set :log_level, :debug

# use sudo
set :use_sudo, true

# Set composer path
set :default_env, { path: "/usr/local/bin:$PATH" }

# Apache users with .htaccess files:
# it needs to be added to linked_files so it persists across deploys:
# set :linked_files, fetch(:linked_files, []).push('.env', 'web/.htaccess')
set :linked_files, fetch(:linked_files, []).push('.env')
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads')

namespace :deploy do

  desc "Checkout subdirectory and delete all the other stuff"
  task :checkout_subdir do
    on roles(:app) do
      execute "mv --backup=numbered #{release_path}/#{fetch(:subdir)}/ /tmp && rm -rf #{release_path}/* && mv /tmp/#{fetch(:subdir)}/* #{release_path}"
     end
  end

end

after "deploy:symlink:linked_dirs", "deploy:checkout_subdir"

namespace :deploy do

  desc "create WordPress files for symlinking"
  task :create_wp_files do
    on roles(:app) do
      #execute :touch, "#{shared_path}/wp-config.php"
      #execute :touch, "#{shared_path}/.htaccess"
      execute :touch, "#{shared_path}/.env"
      #execute :touch, "#{shared_path}/content/plugins/w3tc-wp-loader.php"
    end
  end

  after 'check:make_linked_dirs', :create_wp_files
end

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :service, :nginx, :reload
    end
  end
end

# The above restart task is not run by default
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  desc 'Update WordPress template root paths to point to the new release'
  task :update_option_paths do
    on roles(:app) do
      within fetch(:release_path) do
        if test :wp, :core, 'is-installed'
          [:stylesheet_root, :template_root].each do |option|
            # Only change the value if it's an absolute path
            # i.e. The relative path "/themes" must remain unchanged
            # Also, the option might not be set, in which case we leave it like that
            value = capture :wp, :option, :get, option, raise_on_non_zero_exit: false
            if value != '' && value != '/themes'
              execute :wp, :option, :set, option, fetch(:release_path).join('web/wp/wp-content/themes')
            end
          end
        end
      end
    end
  end
end

# The above update_option_paths task is not run by default
# Note that you need to have WP-CLI installed on your server
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:update_option_paths'

namespace :deploy do
  desc 'Set correct file permissions'
  task :fix_file_permissions do
    on roles(:app) do
      execute :chmod, "777 #{release_path}/web/app"
    end
  end
end

# The above fix_file_permissions task should be executed in order to fix file permissions
after 'deploy:publishing', 'deploy:fix_file_permissions'