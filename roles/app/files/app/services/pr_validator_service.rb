# frozen_string_literal: true

# Service for validating pull requests data
class PrValidatorService
  attr_reader :errors
  
  def initialize
    @errors = []
  end
  
  def validate_pr_file(file_path, authority_names)
    @errors = []
    
    unless File.exist?(file_path)
      @errors << "Pull requests file not found at #{file_path}"
      return false
    end
    
    begin
      pr_data = YAML.load_file(file_path)
    rescue => e
      @errors << "Failed to parse YAML file: #{e.message}"
      return false
    end
    
    unless pr_data.is_a?(Array)
      @errors << "Pull requests data should be an array"
      return false
    end
    
    pr_data.each_with_index do |pr, index|
      validate_pr(pr, index + 1, authority_names)
    end
    
    return @errors.empty?
  end
  
  private
  
  def validate_pr(pr, index, authority_names)
    # Check required fields
    required_fields = ['title', 'url', 'created_at', 'affected_authorities']
    missing_fields = required_fields.select { |field| pr[field].nil? }
    
    if missing_fields.any?
      @errors << "PR ##{index}: Missing required fields: #{missing_fields.join(', ')}"
    end
    
    # Validate dates
    ['created_at', 'closed_at'].each do |date_field|
      next unless pr[date_field]
      
      begin
        Date.parse(pr[date_field])
      rescue ArgumentError
        @errors << "PR ##{index}: Invalid date format for #{date_field}: #{pr[date_field]}"
      end
    end
    
    # Validate closed/accepted logic
    if pr['closed_at'].nil? && pr['accepted']
      @errors << "PR ##{index}: PR is marked as accepted but has no closed_at date"
    end
    
    # Validate affected authorities
    if pr['affected_authorities'].is_a?(Array)
      invalid_authorities = pr['affected_authorities'].reject { |auth| authority_names.include?(auth) }
      
      if invalid_authorities.any?
        @errors << "PR ##{index}: Invalid authority short names: #{invalid_authorities.join(', ')}"
      end
    else
      @errors << "PR ##{index}: affected_authorities must be an array"
    end
  end
end
