# frozen_string_literal: true

# Support methods to break up urls like:
# * https://github.com/planningalerts-scrapers/issues/issues/1053
# * https://github.com/planningalerts-scrapers/multiple_icon/pull/23
# into repo, owner, number
module RepoOwnerNumberHtmlUrl
  # Extracts repo from html_yrl, "issues" and "multiple_icon" in the examples above
  def repo
    html_url.split('/')[-3]
  end

  # Extract owner from html_url, "planningalerts-scrapers" in the examples above
  def owner
    html_url.split('/')[-4]
  end

  def number
    html_url.split('/')[-1].to_i
  end
end
