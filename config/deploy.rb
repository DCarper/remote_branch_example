require 'capistrano_colors'
set :user, "dancarper"

set :application, "remote_cache"
default_run_options[:pty] = true
set :repository,  "git@github.com:DCarper/example_old_deploy.git"


set :scm, :git
set :scm_command, "/usr/local/git/bin/git"

set :branch, "master"

set :deploy_to, "~dancarper/code/deployments/#{application}"
set :deploy_via, :remote_cache

set :port, "22"
set :domain, "192.168.2.2"

role :web, domain                         # Your HTTP server, Apache/etc
role :app, domain                         # This may be the same as your `Web` server
role :db,  domain, :primary => true       # This is where Rails migrations will run

set :runner, user

namespace :deploy do

	#
	# no-op-ify some default tasks
	#

  [:start, :stop, :restart].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

	task :migrate do ; end

end
