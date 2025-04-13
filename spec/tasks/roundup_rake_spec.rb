# frozen_string_literal: true

require_relative '../spec_helper'

# Load the rake files
require 'rake'
load File.expand_path('../../app/tasks/roundup.rake', __dir__)
load File.expand_path('../../app/tasks/import.rake', __dir__)
load File.expand_path('../../app/tasks/generate.rake', __dir__)
load File.expand_path('../../app/tasks/singleton.rake', __dir__)

RSpec.describe 'roundup.rake tasks' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    RSpec::Mocks.space.reset_all
    Rake::Task.tasks.each(&:reenable)
  end

  describe 'roundup:all' do
    it 'depends on singleton, import:all and generate:all and outputs a message' do
      app_helpers.roundup_finished!

      # First verify the prerequisites
      task = Rake::Task['roundup:all'].dup
      expected_prereqs = %w[analyze:all flag_finished flag_updating generate:all import:all singleton]
      expect(task.prerequisites).to match_array(expected_prereqs)

      # Clear prerequisites from the copy and run
      task.instance_variable_set(:@prerequisites, [])

      expect { task.invoke }.to output(/Finished roundup:all/).to_stdout
    end
  end

  describe 'roundup:github' do
    it 'depends on singleton, import:github and generate:github and outputs a message' do
      app_helpers.roundup_finished!

      # First verify the prerequisites
      task = Rake::Task['roundup:github'].dup
      expected_prereqs = %w[flag_finished flag_updating generate:github import:github singleton]
      expect(task.prerequisites).to match_array(expected_prereqs)

      # Clear prerequisites from the copy and run
      task.instance_variable_set(:@prerequisites, [])

      expect { task.invoke }.to output(/Finished roundup:github/).to_stdout
    end
  end
end
