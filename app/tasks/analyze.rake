# frozen_string_literal: true

namespace :analyze do
  desc 'Analyze everything'
  task all: %i[singleton broken_scores] do
    puts 'Finished'
  end

  desc 'Calculate and update broken scores for authorities and scrapers'
  task :broken_scores do
    BrokenScoreAnalyzer.update_scores
  end
end
