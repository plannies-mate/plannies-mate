# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/generators/authorities_generator'
require_relative '../../app/generators/authority_generator'
require_relative '../../app/generators/scrapers_generator'
require_relative '../../app/generators/scraper_generator'

# Load the rake file
require 'fileutils'
require 'rake'

load File.expand_path('../../app/tasks/generate.rake', __dir__)
load File.expand_path('../../app/tasks/singleton.rake', __dir__)


RSpec.describe 'generate.rake tasks' do
  before do
    Rake::Task.tasks.each(&:reenable)
    Rake::Task.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    # Clean up
    FileUtils.rm_rf(AuthoritiesGenerator.site_dir)
    RSpec::Mocks.space.reset_all
  end

  describe 'generate:authorities' do
    it 'calls AuthoritiesGenerator.generate' do
      expect(AuthoritiesGenerator).to receive(:generate)
      task = Rake::Task['generate:authorities']
      task.invoke
    end
  end

  describe 'generate:authority_pages' do
    it 'calls AuthorityGenerator.generate_all' do
      expect(AuthorityGenerator).to receive(:generate_all)
      task = Rake::Task['generate:authority_pages']
      task.invoke
    end
  end

  describe 'generate:scrapers' do
    it 'calls ScrapersGenerator.generate' do
      expect(ScrapersGenerator).to receive(:generate)
      task = Rake::Task['generate:scrapers']
      task.invoke
    end
  end

  describe 'generate:scraper_pages' do
    it 'calls ScraperGenerator.generate_all' do
      expect(ScraperGenerator).to receive(:generate_all)
      task = Rake::Task['generate:scraper_pages']
      task.invoke
    end
  end

  describe 'generate:all' do
    it 'calls all singleton task then generators in order' do
      expect(SimplePidFile).to receive(:new).ordered.with('plannies-mate-task')
      # We need to know the order, so we'll verify it with call counts
      expect(AuthoritiesGenerator).to receive(:generate).ordered
      expect(AuthorityGenerator).to receive(:generate_all).ordered
      expect(ScrapersGenerator).to receive(:generate).ordered
      expect(ScraperGenerator).to receive(:generate_all).ordered

      task = Rake::Task['generate:all']
      task.invoke
    end
  end
end
