# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../lib/simple_pid_file'

# Load the rake file
require 'rake'
load File.expand_path('../../app/tasks/singleton.rake', __dir__)

RSpec.describe 'singleton.rake task' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    RSpec::Mocks.space.reset_all
    Rake::Task.tasks.each(&:reenable)
  end

  describe 'singleton task' do
    it 'creates a SimplePidFile instance' do
      expect(SimplePidFile).to receive(:new).with('plannies-mate-task')
      Rake::Task['singleton'].invoke
    end
  end
end
