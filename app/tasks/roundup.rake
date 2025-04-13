# frozen_string_literal: true

namespace :roundup do
  desc 'Roundup everything (daily)'
  task all: %i[singleton flag_updating import:all analyze:all generate:all flag_finished] do
    puts 'Finished roundup:all'
  end

  desc 'Roundup changes from github (every 15 minutes)'
  task github: %i[singleton flag_updating import:github generate:github flag_finished] do
    puts 'Finished roundup:github'
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
