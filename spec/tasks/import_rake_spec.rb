# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/authorities_importer'
require_relative '../../app/importers/issues_importer'

# Load the rake file
require 'rake'
load File.expand_path('../../app/tasks/import.rake', __dir__)
load File.expand_path('../../app/tasks/singleton.rake', __dir__)

RSpec.describe 'import.rake tasks' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?

    @authorities_importer = AuthoritiesImporter.new
    @issues_importer = IssuesImporter.new
  end

  after do
    # Clean up
    FileUtils.rm_rf(AuthoritiesGenerator.site_dir)
    RSpec::Mocks.space.reset_all
  end

  describe 'import:authorities' do
    it 'calls singleton then creates an AuthoritiesImporter and calls import' do
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(AuthoritiesImporter).to receive(:new).ordered.and_return(@authorities_importer)
      expect(@authorities_importer).to receive(:import).ordered
      Rake::Task['import:authorities'].invoke
    end
  end

  describe 'import:issues' do
    it 'calls singleton then creates an IssuesImporter and calls import' do
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(IssuesImporter).to receive(:new).ordered.and_return(@issues_importer)
      expect(@issues_importer).to receive(:import).ordered
      Rake::Task['import:issues'].invoke
    end
  end

  describe 'import:all' do
    it 'calls singleton and both import tasks in order' do
      # We'll verify the order by using ordered expectations
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(AuthoritiesImporter).to receive(:new).ordered.and_return(@authorities_importer)
      expect(@authorities_importer).to receive(:import).ordered
      expect(IssuesImporter).to receive(:new).ordered.and_return(@issues_importer)
      expect(@issues_importer).to receive(:import).ordered

      Rake::Task['import:all'].invoke
    end
  end
end
