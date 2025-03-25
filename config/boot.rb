# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
ENV['RACK_ENV'] ||= ENV['APP_ENV'] || ENV['RAILS_ENV'] || 'development'
ENV['APP_ENV'] = nil
ENV['RAILS_ENV'] = nil

# Setup gems for sections, :app and/or :tasks
def require_gems_for(*sections)
  Bundler.require(:default, ENV['RACK_ENV'].to_sym, *sections)
end
