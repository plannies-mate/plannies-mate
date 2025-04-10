# frozen_string_literal: true

namespace :analyze do
  desc 'Calculate and update broken scores for authorities and scrapers'
  task :broken_scores do
    BrokenScoreAnalyzer.update_scores
  end
end
