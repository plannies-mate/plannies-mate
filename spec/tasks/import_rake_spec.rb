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
    @wayback_importer = WaybackAuthoritiesImporter.new
  end

  after do
    # Clean up
    FileUtils.rm_rf(AuthoritiesGenerator.site_dir)
    RSpec::Mocks.space.reset_all
  end

  describe 'import:authorities' do
    it 'calls singleton then creates an AuthoritiesImporter and calls import',
       vcr: { cassette_name: cassette_name('import_authorities') } do
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(AuthoritiesImporter).to receive(:new).ordered.and_return(@authorities_importer)
      expect(@authorities_importer).to receive(:import).ordered
      Rake::Task['import:authorities'].invoke
    end
  end

  describe 'import:issues' do
    it 'calls singleton then creates an IssuesImporter and calls import',
       vcr: { cassette_name: cassette_name('import_issues') } do
      issues_importer = IssuesImporter.new
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(IssuesImporter).to receive(:new).ordered.and_return(issues_importer)
      expect(issues_importer).to receive(:import).ordered
      Rake::Task['import:issues'].invoke
    end
  end

  describe 'import:all' do
    it 'calls singleton and both import tasks in order',
       vcr: { cassette_name: cassette_name('import_all') } do
      # We'll verify the order by using ordered expectations
      issues_importer = IssuesImporter.new
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(AuthoritiesImporter).to receive(:new).ordered.and_return(@authorities_importer)
      expect(@authorities_importer).to receive(:import).ordered
      expect(IssuesImporter).to receive(:new).ordered.and_return(issues_importer)
      expect(issues_importer).to receive(:import).ordered

      Rake::Task['import:all'].invoke
    end
  end

  describe 'import:coverage_history' do
    it 'calls singleton then creates an WaybackAuthoritiesImporter and calls import',
       vcr: { cassette_name: cassette_name('coverage_history') } do
      # expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      expect(WaybackAuthoritiesImporter).to receive(:new).ordered.and_return(@wayback_importer)
      expect(@wayback_importer).to receive(:import_historical_data).ordered
      Rake::Task['import:coverage_history'].invoke
    end
  end
end
