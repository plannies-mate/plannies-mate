# frozen_string_literal: true

require 'fileutils'
require_relative '../spec_helper'

RSpec.describe SlimHelper do
  let(:test_path) { 'test_view' }
  let(:app_helpers) { App.app_helpers }
  let(:test_dir) { File.join(app_helpers.views_dir, test_path) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p(test_dir)
  end

  after do
    # Clean up test files
    FileUtils.rm_rf(test_dir)
  end

  describe '#add_slim_extensions' do
    before do
      # Create test files with different extensions
      FileUtils.touch(File.join(test_dir, ',existing.slim'))
      FileUtils.touch(File.join(test_dir, ',another.html.slim'))
      FileUtils.touch(File.join(test_dir, ',plain'))
    end

    it 'returns path with .slim if it exists' do
      result = app_helpers.add_slim_extensions(File.join(test_dir, ',existing'))
      expect(result).to end_with(',existing.slim')
    end

    it 'returns path with .html.slim if it exists' do
      result = app_helpers.add_slim_extensions(File.join(test_dir, ',another'))
      expect(result).to end_with(',another.html.slim')
    end

    it 'returns original path if no extensions match' do
      result = app_helpers.add_slim_extensions(File.join(test_dir, 'nonexistent'))
      expect(result).to end_with('nonexistent')
    end

    it 'returns path without extension if file exists without extension' do
      result = app_helpers.add_slim_extensions(File.join(test_dir, ',plain'))
      expect(result).to end_with(',plain')
    end
  end
end
