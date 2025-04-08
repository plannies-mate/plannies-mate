# frozen_string_literal: true

# Application wide Helper methods and CONSTANTS
# use `extend ApplicationHelper` so everything become class methods
module ApplicationHelper
  # Standardized logging with timestamp
  def log(message)
    puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - #{message}"
  end

  def rack_env
    ENV['RACK_ENV'] || 'development'
  end

  def production?
    rack_env == 'production'
  end

  def test?
    rack_env == 'test'
  end

  def development?
    rack_env == 'development'
  end

  # Project root dir
  def root_dir
    File.expand_path('../../', __dir__)
  end

  # Status and other variable files for this project
  def var_dir
    File.expand_path('var', root_dir)
  end

  # View templates dir
  def views_dir
    File.expand_path('app/views', root_dir)
  end

  # Html site dir
  def site_dir
    if production?
      '/var/www/html'
    elsif test?
      File.expand_path('tmp/html-test', root_dir)
    elsif development?
      File.expand_path('tmp/html', root_dir)
    else
      raise "RACK_ENV must be 'production' or 'test' or 'development' (default)."
    end
  end

  def git_commit
    begin
      commit_file = File.join(root_dir, 'REVISION')
      @git_commit ||= File.read(commit_file).strip if File.exist?(commit_file)
      @git_commit ||= `git rev-parse HEAD`.strip
    rescue StandardError => e
      puts "Error getting git commit: #{e.message}"
    end
    @git_commit.presence
  end

  def force?
    !ENV['FORCE'].blank?
  end

  def debug?
    !ENV['DEBUG'].blank?
  end
end
