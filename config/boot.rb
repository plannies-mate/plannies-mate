# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

deploy_env = File.expand_path('deploy_env.rb', __dir__)
require_relative 'deploy_env' if File.exist?(deploy_env)

ENV['RACK_ENV'] ||= ENV['APP_ENV'] || ENV['RAILS_ENV'] || 'development'
ENV['APP_ENV'] = nil
ENV['RAILS_ENV'] = nil

# Setup gems for sections, :app and/or :tasks
def require_gems_for(*groups, description)
  @loaded_groups ||= Set.new

  groups_to_load = [:default, ENV['RACK_ENV'].to_sym] + groups - @loaded_groups.to_a
  return if groups_to_load.empty?

  puts "Bundle required #{groups_to_load.inspect} #{@loaded_groups.empty? ? '' : 'extra '}groups for #{description}"
  Bundler.require(*groups_to_load)
  @loaded_groups.merge(groups_to_load)
end
