# frozen_string_literal: true

require_relative 'tasks'
require_gems_for(:tasks)

require 'rake'
require 'sinatra/activerecord/rake'
require_relative 'app/lib/app_helpers_accessor'
# Load all task definitions from app/tasks
Dir.glob(File.join(File.dirname(__FILE__), 'app/tasks/**/*.rake')).each { |r| load r }

# Default task shows help
# task :default do
#   system('rake -T')
# end
