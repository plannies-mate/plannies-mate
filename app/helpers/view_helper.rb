# frozen_string_literal: true

# View Helper methods and CONSTANTS
# use `extend ViewHelper` so everything become class methods
# except in AppContext, in which case use `include ViewHelper`
module ViewHelper
  def number_with_delimiter(number)
    return number if number.nil?

    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end

  # Format a date nicely
  def format_date(date_string)
    return date_string if date_string.nil?

    begin
      date = Date.parse(date_string.to_s)
      date.strftime('%d %b %Y')
    rescue StandardError
      date_string
    end
  end

  # Get CSS class based on status
  def status_class(warning)
    warning ? 'status-warning' : 'status-ok'
  end

  def summarize_authorities(authorities)
    bad_count = authorities.count(&:possibly_broken?)
    "#{bad_count} have warnings"
  end

  # Add this to your AppContext class
  def is_light_color?(hex_color)
    # Remove leading '#' if present
    hex_color = hex_color.gsub(/^#/, '')

    # Convert hex to RGB
    r = hex_color[0..1].to_i(16)
    g = hex_color[2..3].to_i(16)
    b = hex_color[4..5].to_i(16)

    # Calculate brightness using the formula
    # Brightness = (0.299*R + 0.587*G + 0.114*B)
    brightness = ((0.299 * r) + (0.587 * g) + (0.114 * b))

    # If brightness is greater than 150, color is light; otherwise, it's dark
    brightness > 150
  end

  def css_class_for_label(label, broken_authority)
    if label.name == 'probably fixed' && broken_authority
      'issue-label-strikethrough '
    else
      ''
    end +
      if is_light_color?(label.color)
        'issue-label-dark-text issue-label-light-border'
      else
        'issue-label-light-text'
      end
  end

  def suggest_close_issue?(authority, issue)
    authority.week_count.positive? &&
      authority.month_count > authority.week_count &&
      issue.labels.none? { |lab| lab.name == 'probably fixed' }
  end
end
