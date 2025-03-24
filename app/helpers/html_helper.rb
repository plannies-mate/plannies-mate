# frozen_string_literal: true

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
      "/#{model.class.name.downcase.pluralize}/#{model.to_param}"
    elsif model.respond_to?(:html_url)
      model.html_url
    end
  end
end
