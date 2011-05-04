require 'capistrano_colors'

set :user, "dancarper"

default_run_options[:pty] = true
set :repository, "git@github.com:DCarper/new_deploy.git"

set :scm, :git
set :branch, "master"

set :port, "22"
set :domain, "192.168.2.2"

role :web, domain # Your HTTP server, Apache/etc
role :app, domain # This may be the same as your `Web` server
role :db, domain, :primary => true # This is where Rails migrations will run

set :runner, user

set :rails_env, 'production'

set :deploy_to, "~dancarper/code/deployments/new"


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
    
  desc "Deploy aw yeaaah!"
  task :default do
    update
    restart
  end
  
  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do

    # read the latest deploy number from the shared DEPLOY file, increment, and write it back
    #
    # if it fails then the number will be 0
    #
    new_num = next_branch_num()
    
    deleting_deploy_num = new_num.to_i - 10

    new_branch_name = "#{branch}#{new_num}"
    branch_for_delete = "#{branch}#{deleting_deploy_num}"
    
    on_rollback { rollback }

    # update the origin
    run "cd #{current_path}; git fetch origin;"

    # create a new tracking branch for the current version of that branch
    run "cd #{current_path}; git branch -f --track #{new_branch_name} origin/#{branch};"

    #switch to it
    run "cd #{current_path}; git checkout #{new_branch_name};"

    #delete the 10-ago-branch ... don't fail if it doesn't exist.
    begin
      run "cd #{current_path}; git branch -D #{branch_for_delete} >/dev/null 2>&1"
    rescue
    end
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
    restart
  end

  desc <<-DESC
    always current_path
  DESC
  task :migrate, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "production")
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then current_path
      else   raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    puts "#{migrate_target} => #{directory}"
    run "cd #{directory}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate; git commit -m 'schema.rb updates'"
  end

  desc <<-DESC
    no-op with gitty deployment
  DESC
  task :symlink, :except => { :no_release => true } do ; end

  namespace "rollback" do
    desc "Rollback a single commit."
    task :code, :except => { :no_release => true } do

			# read the latest deploy number from the shared DEPLOY file, decrement, and write it back
			old_num = old_branch_num()

			old_branch_name = "#{branch}#{old_num}"

			# switch to the last branch
			run "cd #{current_path}; git checkout #{old_branch_name}"

			# restart
			deploy.restart
    end
    
    desc "Roll back some code"
    task :default do
      rollback.code
    end
  end

  desc "no op"
  task :cleanup do ; end
  
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

