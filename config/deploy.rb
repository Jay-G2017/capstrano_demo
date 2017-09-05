# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'capstrano_demo'
set :repo_url, 'https://github.com/Jay-G2017/capstrano_demo'
set :pid_file, "#{deploy_to}/current/tmp/pids/unicorn.pid"
set :unicorn_config_file, "#{current_path}/config/unicorn.rb"
set :listen_port, 5000

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/var/www/capstrano_demo'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'vendor/bundle')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }
set :bundle_flags, '--local --deployment --quiet'

# Default value for keep_releases is 5
set :keep_releases, 2

set :rvm_type, :auto                     # Defaults to: :auto
set :rvm_ruby_version, '2.3.3'      # Defaults to: 'default'

namespace :deploy do
  task :start do
    on roles(:app) do
      execute %{source /etc/profile.d/rvm.sh && cd #{current_path} && if [ ! -f #{fetch(:pid_file)} ]; then UNICORN_WORKER_NUM=#{fetch(:unicorn_worker_num)} RAILS_ENV=#{fetch(:env)} APP_PORT=#{fetch(:listen_port)} bundle exec unicorn -c #{fetch(:unicorn_config_file)} -D; fi}
    end
  end

  task :stop do
    on roles(:app) do
      execute %{source /etc/profile.d/rvm.sh && cd #{current_path} && if [ -f #{fetch(:pid_file)} ] && kill -0 `cat #{fetch(:pid_file)}`> /dev/null 2>&1; then kill -QUIT `cat #{fetch(:pid_file)}`; else rm #{fetch(:pid_file)} || exit 0; fi}
    end
  end

  task :restart do
    on roles(:app) do
      execute %{source /etc/profile.d/rvm.sh && cd #{current_path} && if [ -f #{fetch(:pid_file)} ] && kill -0 `cat #{fetch(:pid_file)}`> /dev/null 2>&1; then kill -HUP `cat #{fetch(:pid_file)}`; else rm #{fetch(:pid_file)} || UNICORN_WORKER_NUM=#{fetch(:unicorn_worker_num)} RAILS_ENV=#{fetch(:env)} APP_PORT=#{fetch(:listen_port)} bundle exec unicorn -c #{fetch(:unicorn_config_file)} -D; fi}
    end
  end

  task :localize_config do
    on roles(:app) do
      execute "cd #{current_path} && echo #{fetch(:apns_prefix)} > config/apns_prefix.txt"
    end
  end

  desc "initialize the server folders"
  task :setup do
    on roles(:app) do
      execute "mkdir -p #{deploy_to}/releases"
      execute "mkdir -p #{deploy_to}/shared/log"
      execute "mkdir -p #{deploy_to}/shared/tmp/pids"
      execute "mkdir -p #{deploy_to}/shared/public"
      execute "mkdir -p #{deploy_to}/shared/tmp"
    end
  end

  after 'deploy:symlink:release', 'deploy:localize_config'
  after :finishing, 'deploy:cleanup'
end
