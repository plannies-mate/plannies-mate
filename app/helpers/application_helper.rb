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

  def var_dir
    File.expand_path('../../var', __dir__)
  end

  def views_dir
    File.expand_path('../views', __dir__)
  end

  def site_dir
    if production?
      '/var/www/html'
    elsif test?
      File.expand_path('../../../../../tmp/html-test', __dir__)
    elsif development?
      File.expand_path('../../../../../tmp/html', __dir__)
    else
      raise "RACK_ENV must be 'production' or 'test' or 'development' (default)."
    end
  end

  def force?
    !ENV['FORCE'].blank?
  end

  def debug?
    !ENV['DEBUG'].blank?
  end
end
