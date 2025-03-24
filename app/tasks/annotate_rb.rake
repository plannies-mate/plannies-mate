# frozen_string_literal: true

# This rake task was copied from annotate_rb gem and adjusted as needed.

# Can set `ANNOTATERB_SKIP_ON_DB_TASKS` to be anything to skip this
if ENV.fetch('RACK_ENV', 'development') == 'development' && ENV['ANNOTATERB_SKIP_ON_DB_TASKS'].nil?
  require 'annotate_rb'

  AnnotateRb::Core.load_rake_tasks
end
