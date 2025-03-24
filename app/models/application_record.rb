# frozen_string_literal: true

require 'active_record'
require_relative '../lib/app_helpers_accessor'

# Base Application for site wide model configuration
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  include AppHelpersAccessor
end
