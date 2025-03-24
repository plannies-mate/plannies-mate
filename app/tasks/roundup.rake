# frozen_string_literal: true

namespace :roundup do
  desc 'Roundup everything (import, generate)'
  task all: %i[singleton import:all generate:all] do
    # also  pull_requests:update_status coverage_history:import_current
    puts 'Finished roundup:all'
  end

  desc 'Roundup if requested'
  task if_requested: %i[singleton] do
    if App.app_helpers.roundup_requested?
      puts 'Running roundup:all task as requested'
      Rake::Task['roundup:all'].invoke
    else
      puts 'No roundup requested'
    end
  end
end
