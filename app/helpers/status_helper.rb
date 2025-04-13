# frozen_string_literal: true

# Helper methods and CONSTANTS
# use `extend StatusHelper` so everything become class methods
module StatusHelper
  def roundup_request_file
    File.join(var_dir, 'roundup_request.dat')
  end

  def update_status_file
    File.join(site_dir, 'assets', 'css', 'update_status.css')
  end

  def roundup_requested?
    File.exist?(roundup_request_file)
  end

  def roundup_requested!
    FileUtils.mkdir_p(File.dirname(roundup_request_file))
    File.write(roundup_request_file, Time.now.to_s)
    FileUtils.mkdir_p(File.dirname(update_status_file))
    FileUtils.rm_f(update_status_file)
    File.symlink('update_requested.css', update_status_file)
  end

  def roundup_updating!
    FileUtils.mkdir_p(File.dirname(roundup_request_file))
    File.write(roundup_request_file, Time.now.to_s)
    FileUtils.mkdir_p(File.dirname(update_status_file))
    FileUtils.rm_f(update_status_file)
    File.symlink('updating.css', update_status_file)
  end

  def roundup_finished!
    FileUtils.rm_f(roundup_request_file)
    FileUtils.mkdir_p(File.dirname(update_status_file))
    FileUtils.rm_f(update_status_file)
    File.symlink('not_updating.css', update_status_file)
  end

  # Helper for human-readable time differences
  def time_ago_in_words(from_time)
    distance_in_seconds = (Time.now - from_time).round
    case distance_in_seconds
    when 0..10
      'just now'
    when 10..(99.94 * 60)
      "#{(distance_in_seconds / 60.0).round(1)} minutes ago"
    when 999..(99.94 * 3600)
      "#{(distance_in_seconds / 3600.0).round(1)} hours ago"
    else
      "#{(distance_in_seconds / (24 * 3600.0)).round(1)} days ago"
    end
  end
end
