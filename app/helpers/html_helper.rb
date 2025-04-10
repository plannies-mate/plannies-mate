# frozen_string_literal: true

require 'uri'

# Helper methods for Html string formatting in views
module HtmlHelper
  # Add word break opportunities (<wbr>) after specified punctuation
  # Particularly useful for long identifiers with underscore/hyphen separators
  # @param str [String] the string to process
  # @param chars [String] characters after which to insert <wbr> tags
  # @return [String] the string with <wbr> tags inserted
  def add_word_breaks(str, chars = '-_.')
    return str if str.nil? || str.empty?

    # Escape characters for use in regex
    escaped_chars = Regexp.escape(chars)
    # Insert <wbr> after each specified character
    str.gsub(/([#{escaped_chars}])/, '\1<wbr>')
  end

  # Path for resource
  def path_for(model)
    if model.respond_to?(:to_param)
      "/#{model.class.name.underscore.pluralize}/#{model.to_param}"
    elsif model.respond_to?(:html_url)
      model.html_url
    end
  end

  def last_url_segment(url)
    URI(url).path.split('/').reject(&:empty?).last
  end

  def authority_status_class(authority)
    status_class = if authority.mine?
                     'status-mine'
                   elsif authority.open_pull_requests?
                     'status-pull-request'
                   elsif authority.others?
                     if authority.blocked?
                       'status-blocked'
                     else
                       'status-others'
                     end
                   elsif authority.last_received || authority.possibly_broken?
                     if authority.blocked?
                       'status-blocked'
                     else
                       'status-warning'
                     end
                   else
                     'status-ok'
                   end
    "authority-status #{status_class}"
  end

  def authority_status_title(authority)
    if authority.last_received
      "Broke #{authority.last_received.strftime('%b %Y')}"
    elsif authority.possibly_broken?
      'Possibly Broken'
    else
      'Receiving applications'
    end
  end

  def authority_status_description(authority)
    if authority.mine?
      'My issue'
    elsif authority.open_pull_requests?
      'PR under review'
    elsif authority.others?
      if authority.blocked?
        'Blocked by authority'
      else
        'Others issue'
      end
    elsif authority.last_received
      if authority.blocked?
        "Blocked #{authority.last_received.strftime('%b %Y')}"
      else
        "Broke #{authority.last_received.strftime('%b %Y')}"
      end
    elsif authority.possibly_broken?
      if authority.blocked?
        'Possibly Blocked'
      else
        'Possibly Broken'
      end
    else
      'OK'
    end
  end

  def authority_status_icon_class(authority)
    if authority.mine?
      'fa-solid fa-user-gear'
    elsif authority.open_pull_requests?
      'fa-solid fa-code-pull-request'
    elsif authority.others?
      'fa-solid fa-user-pen'
    elsif authority.last_received || authority.possibly_broken?
      if authority.blocked?
        'fa-solid fa-building-lock'
      else
        'fa-solid fa-exclamation-triangle'
      end
    else
      'fa-solid fa-check-circle'
    end
  end
end
