require 'capistrano_colors'

set :user, "dancarper"

default_run_options[:pty] = true
set :repository, "git@github.com:DCarper/new_deploy.git"

set :scm, :git
set :scm_command, "/usr/local/git/bin/git"

set :branch, "master"

set :port, "22"
set :domain, "192.168.2.2"

role :web, domain # Your HTTP server, Apache/etc
role :app, domain # This may be the same as your `Web` server
role :db, domain, :primary => true # This is where Rails migrations will run

set :runner, user

set :application, 'spring_cleaning'
set :deploy_to, "~dancarper/code/deployments/#{application}"


#$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
#require "rvm/capistrano"                  # Load RVM's capistrano plugin.
#set :rvm_ruby_string, 'ree@4moms'        # Or whatever env you want it to run in.

task :production do
  
end

task :testy do
	puts current_path;
	puts shared_path;
end

namespace :deploy do

	desc "Deploy the MFer"
  task :default do
    update
    restart
    cleanup
  end

  desc "Setup a GitHub-style deployment."
  task :setup, :except => { :no_release => true } do
    run "git clone #{repository} #{current_path}"
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
  end

  desc "Rollback a single commit."
  task :rollback, :except => { :no_release => true } do
    set :branch, "HEAD^"
    default
  end
	  desc <<-DESC
    Deploys and starts a `cold' application. This is useful if you have not \
    deployed your application before, or if your application is (for some \
    other reason) not currently running. It will deploy the code, run any \
    pending migrations, and then instead of invoking `deploy:restart', it will \
    invoke `deploy:start' to fire up the application servers.
  DESC
  task :cold do
    update
  end

  desc <<-DESC
    always current_path
  DESC
  task :migrate, :roles => :db, :only => { :primary => true } do ; end

  desc <<-DESC
    no-op with gitty deployment
  DESC
  task :symlink, :except => { :no_release => true } do ; end

  desc "no op"
  task :cleanup do ; end

  [:start, :stop, :restart].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
end

class Capistrano::Configuration
	#
  ##
  # Run a command and return the result as a string.
  #
  # TODO May not work properly on multiple servers.
  
  def run_and_return(cmd)
    output = []
    run cmd do |ch, st, data|
      output << data
    end
    return output.to_s
  end

	def next_branch_num
		begin
      new_num = run_and_return("cd #{shared_path}; cat DEPLOY").strip.to_i + 1
      run "cd #{shared_path}; echo #{new_num} > DEPLOY"
			new_num
    rescue
      0
    end
	end

	def old_branch_num
    begin
      old_num = run_and_return("cd #{shared_path}; cat DEPLOY").strip.to_i - 1
      run "cd #{shared_path}; echo #{old_num} > DEPLOY"
			old_num
    rescue
      0
    end
	end

  
end

