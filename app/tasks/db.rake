Rake::Task['db:fixtures:load'].clear

namespace :db do
  desc 'Database Stats'
  task :stats do
    puts format('%-30s %8s %-30s', 'Table', 'Count', 'Last Modified')
    puts format('%-30s %8s %-30s', '-' * 30, '-' * 8, '-' * 30)
    ActiveRecord::Base.connection.tables.sort.each do |t|
      res = begin
        ActiveRecord::Base.connection.exec_query("select count(*), max(updated_at) from #{t}")
      rescue StandardError
        ActiveRecord::Base.connection.exec_query("select count(*),'' from #{t}")
      end
      row = res.rows.first
      puts format('%-30s %8d %-30s', t, row[0], row[1].to_s)
    end
    puts '', "Status as of #{Time.new.utc}"
  end

  namespace :fixtures do
    desc 'Load fixtures into the current environment\'s database'
    task :load do
      require_relative '../../spec/support/fixture_helper'
      FixtureHelper.clear_database
      FixtureHelper.load_fixtures
    end
  end
end
