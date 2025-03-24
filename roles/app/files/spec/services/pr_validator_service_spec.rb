# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/services/pr_validator_service'

RSpec.describe PrValidatorService do
  let(:service) { described_class.new }
  let(:valid_authorities) { ['brimbank', 'bunbury', 'burwood'] }
  
  describe '#validate_pr_file' do
    it 'returns false when file does not exist' do
      expect(File).to receive(:exist?).with('nonexistent.yml').and_return(false)
      
      result = service.validate_pr_file('nonexistent.yml', valid_authorities)
      
      expect(result).to be false
      expect(service.errors).to include(/not found/)
    end
    
    it 'returns false when YAML is invalid' do
      temp_file = Tempfile.new(['invalid', '.yml'])
      temp_file.write("this: is not: valid: yaml")
      temp_file.close
      
      result = service.validate_pr_file(temp_file.path, valid_authorities)
      
      expect(result).to be false
      expect(service.errors).to include(/Failed to parse YAML/)
      
      temp_file.unlink
    end
    
    it 'returns false when data is not an array' do
      temp_file = Tempfile.new(['not_array', '.yml'])
      temp_file.write("this_is_not_an_array: true")
      temp_file.close
      
      result = service.validate_pr_file(temp_file.path, valid_authorities)
      
      expect(result).to be false
      expect(service.errors).to include(/should be an array/)
      
      temp_file.unlink
    end
    
    it 'validates each PR in the array' do
      temp_file = Tempfile.new(['valid_prs', '.yml'])
      temp_file.write(YAML.dump([
        {
          'title' => 'Valid PR',
          'url' => 'https://github.com/example/repo/pull/1',
          'created_at' => '2025-03-20',
          'affected_authorities' => ['brimbank']
        },
        {
          'title' => 'Invalid PR',
          'url' => 'https://github.com/example/repo/pull/2',
          'created_at' => '2025-03-21',
          'affected_authorities' => ['not_real_authority']
        }
      ]))
      temp_file.close
      
      result = service.validate_pr_file(temp_file.path, valid_authorities)
      
      expect(result).to be false
      expect(service.errors.size).to eq(1)
      expect(service.errors.first).to include('not_real_authority')
      
      temp_file.unlink
    end
    
    it 'returns true when all PRs are valid' do
      temp_file = Tempfile.new(['valid_prs', '.yml'])
      temp_file.write(YAML.dump([
        {
          'title' => 'Valid PR 1',
          'url' => 'https://github.com/example/repo/pull/1',
          'created_at' => '2025-03-20',
          'affected_authorities' => ['brimbank']
        },
        {
          'title' => 'Valid PR 2',
          'url' => 'https://github.com/example/repo/pull/2',
          'created_at' => '2025-03-21',
          'affected_authorities' => ['bunbury', 'burwood']
        }
      ]))
      temp_file.close
      
      result = service.validate_pr_file(temp_file.path, valid_authorities)
      
      expect(result).to be true
      expect(service.errors).to be_empty
      
      temp_file.unlink
    end
  end
end
