# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
ENV['RACK_ENV'] ||= ENV['APP_ENV'] || ENV['RAILS_ENV'] || 'development'
ENV['APP_ENV'] = nil
ENV['RAILS_ENV'] = nil
Bundler.require(:default, ENV['RACK_ENV'].to_sym)
