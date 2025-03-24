module VcrHelper
  def cassette_name(description)
    # Get the calling file's name and immediate parent directory without extension
    file = caller_locations(1, 1)[0].path.split('/').last(2).join('/').sub(/_spec.rb\z/, '')

    # Clean up the description (remove special chars, convert to snake_case)
    desc = description.to_s.gsub(%r{[^a-z0-9-/]+}, '_')
    file << "/#{desc}" if desc.present?
    file
  end
end
