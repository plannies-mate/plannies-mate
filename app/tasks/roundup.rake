# frozen_string_literal: true

namespace :roundup do
  desc 'Roundup everything (import, generate)'
  task all: %i[singleton flag_updating import:all analyze:all generate:all flag_finished] do
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

  desc 'Set update status to UPDATE REQUESTED'
  task :request_update do
    App.app_helpers.roundup_requested!

    puts 'Update status set to UPDATING'
  end

  desc 'Set update status to UPDATING'
  task :flag_updating do
    App.app_helpers.roundup_updating!

    puts 'Update status set to UPDATING'
  end

  desc 'Set update status to FINISHED UPDATING'
  task :flag_finished do
    App.app_helpers.roundup_finished!

    puts 'Update status set to FINISHED UPDATING'
  end
end
