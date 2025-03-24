# frozen_string_literal: true

# Helper methods and CONSTANTS
# use `extend StatusHelper` so everything become class methods
module StatusHelper
  def roundup_request_file
    File.join(var_dir, 'roundup_request.dat')
  end

  def roundup_requested?
    File.exist?(roundup_request_file)
  end

  def roundup_requested=(value)
    if value
      FileUtils.mkdir_p(File.dirname(roundup_request_file))
      File.write(roundup_request_file, Time.now.to_s)
    else
      FileUtils.rm_f(roundup_request_file)
    end
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
