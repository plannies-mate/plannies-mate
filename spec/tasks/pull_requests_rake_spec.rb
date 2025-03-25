# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'pull_requests.rake' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    RSpec::Mocks.space.reset_all
    Rake::Task.tasks.each(&:reenable)
  end

  describe 'pull_requests:update_metrics' do
    it 'calls update_pr_metrics on CoverageHistory' do
      expect(CoverageHistory).to receive(:update_pr_metrics).and_return(3)

      Rake::Task['pull_requests:update_metrics'].invoke
    end
  end
end
