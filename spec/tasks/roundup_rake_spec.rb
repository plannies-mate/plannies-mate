# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/controllers/roundup_controller'

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
      app_helpers.roundup_requested = false

      # First verify the prerequisites
      task = Rake::Task['roundup:all'].dup
      expected_prereqs = %w[singleton import:all generate:all]
      expect(task.prerequisites).to match_array(expected_prereqs)

      # Clear prerequisites from the copy and run
      task.instance_variable_set(:@prerequisites, [])

      expect { task.invoke }.to output(/Finished roundup:all/).to_stdout
    end
  end

  describe 'roundup:if_requested' do
    after do
      app_helpers.roundup_requested = false
    end

    it 'runs roundup:all when requested' do
      app_helpers.roundup_requested = true

      # Expect roundup:all to be called
      roundup_all = Rake::Task['roundup:all']
      allow(roundup_all).to receive(:invoke)
      expect(roundup_all).to receive(:invoke)

      task = Rake::Task['roundup:if_requested']
      task.reenable
      expect { task.invoke }.to output(/Running roundup:all task as requested/).to_stdout
    end

    it 'does not run roundup:all when not requested' do
      app_helpers.roundup_requested = false

      # Expect roundup:all not to be called
      roundup_all = Rake::Task['roundup:all']
      allow(roundup_all).to receive(:invoke)
      expect(roundup_all).not_to receive(:invoke)

      task = Rake::Task['roundup:if_requested']
      task.reenable
      expect { task.invoke }.to output(/No roundup requested/).to_stdout
    end

    it 'depends on the singleton task' do
      # Expect roundup:all not to be called
      allow(Rake::Task['singleton']).to receive(:invoke)
      expect(Rake::Task['singleton']).not_to receive(:invoke)

      task = Rake::Task['roundup:if_requested']
      task.reenable
      task.invoke
    end
  end
end
