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

  desc 'Set update status to UPDATING'
  task :flag_updating do
    css_dir = File.join(App.app_helpers.site_dir, 'assets', 'css')
    FileUtils.mkdir_p(css_dir)
    status_file = File.join(css_dir, 'update_status.css')

    FileUtils.rm_f(status_file)
    File.symlink('updating.css', status_file)

    puts 'Update status set to UPDATING'
  end

  desc 'Set update status to NOT UPDATING'
  task :flag_finished do
    css_dir = File.join(App.app_helpers.site_dir, 'assets', 'css')
    status_file = File.join(css_dir, 'update_status.css')

    FileUtils.rm_f(status_file)
    File.symlink('not_updating.css', status_file)

    puts 'Update status set to NOT UPDATING'
  end
end
