# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/pr_file_service'

RSpec.describe PrFileService do
  describe '.read_file' do
    it 'returns empty array when file does not exist' do
      expect(File).to receive(:exist?).with('nonexistent.yml').and_return(false)
      
      result = described_class.read_file('nonexistent.yml')
      expect(result).to eq([])
    end
    
    it 'uses default PR_FILE when no file specified' do
      expect(File).to receive(:exist?).with(described_class::PR_FILE).and_return(false)
      
      result = described_class.read_file
      expect(result).to eq([])
    end
    
    it 'reads YAML data from the file' do
      temp_file = Tempfile.new(['test_prs', '.yml'])
      
      test_data = [
        { 'title' => 'Test PR 1', 'url' => 'https://example.com/1' },
        { 'title' => 'Test PR 2', 'url' => 'https://example.com/2' }
      ]
      
      temp_file.write(YAML.dump(test_data))
      temp_file.close
      
      result = described_class.read_file(temp_file.path)
      expect(result).to eq(test_data)
      
      temp_file.unlink
    end
    
    it 'returns empty array for invalid YAML' do
      temp_file = Tempfile.new(['invalid', '.yml'])
      temp_file.write("this: is not: valid: yaml")
      temp_file.close
      
      # Instead of mocking YAML.load_file, create an actual invalid YAML file
      # that will trigger a real Psych::SyntaxError
      
      result = described_class.read_file(temp_file.path)
      expect(result).to eq([])
      
      temp_file.unlink
    end
  end
end
