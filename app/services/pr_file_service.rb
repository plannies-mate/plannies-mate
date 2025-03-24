# frozen_string_literal: true

require 'yaml'

# Service for reading pull requests YAML file
class PrFileService
  PR_FILE = 'db/pull_requests.yml'
  
  def self.read_file(file = nil)
    file ||= PR_FILE
    return [] unless File.exist?(file)

    begin
      YAML.load_file(file) || []
    rescue Psych::SyntaxError => e
      puts "Warning: Failed to parse YAML file #{file}: #{e.message}"
      []
    end
  end
end
