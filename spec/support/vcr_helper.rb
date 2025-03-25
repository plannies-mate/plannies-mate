module VcrHelper
  # Helper function to create cassette names that reflect the spec file and context
  def cassette_name(description)
    # Get the calling file's name without path and extension
    file = caller_locations(1, 1)[0].path.split('/').last.gsub('.rb', '')

    # Clean up the description
    desc = description.to_s.downcase.gsub(/[^a-z0-9]+/, '_')

    "#{file}/#{desc}"
  end
end
