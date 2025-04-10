# frozen_string_literal: true

require_relative '../spec_helper'
require 'rake'

RSpec.describe 'Db rake tasks' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    # Clean up
    RSpec::Mocks.space.reset_all
  end

  describe 'db:stats' do
    it 'outputs record counts for tables' do
      expect do
        Rake::Task['db:stats'].invoke
      end.to output(/authorities\s+#{Authority.count}/).to_stdout
    end
  end
end
