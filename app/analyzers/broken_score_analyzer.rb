# frozen_string_literal: true

class BrokenScoreAnalyzer
  # Weights for the scoring formula components
  POPULATION_FACTOR = 2
  DAYS_BROKEN_FACTOR = 15
  REPORTED_BASE_FACTOR = 2
  ACTIVITY_FACTOR = 3
  POPULATION_REPORT_MODIFIER = 0.1
  DEFAULT_DAYS_BROKEN = 365 # Fallback when last_received is nil

  def self.update_scores
    puts 'Calculating broken scores for authorities...'

    Authority.where(possibly_broken: false).update_all(broken_score: 0)
    authorities = Authority.where(possibly_broken: true)

    authorities.each do |authority|
      broken_score = calculate_authority_score(authority)
      authority.update_column(:broken_score, broken_score)
    end

    puts 'Calculating broken scores for scrapers...'

    scrapers = Scraper.joins(:authorities).where(authorities: { possibly_broken: true }).distinct
    Scraper.where.not(id: scrapers.pluck(:id)).update_all(broken_score: 0)
    scrapers.each do |scraper|
      broken_score = calculate_scraper_score(scraper)
      scraper.update_column(:broken_score, broken_score)
    end
  end

  def self.calculate_authority_score(authority)
    days_broken = if authority.last_received.present?
                    (Date.today - authority.last_received).to_i
                  else
                    DEFAULT_DAYS_BROKEN # Default for authorities that never received data
                  end

    population_factor = Math.sqrt(authority.population) * POPULATION_FACTOR if authority.population&.positive?
    days_broken_factor = Math.sqrt(days_broken + 1) * DAYS_BROKEN_FACTOR

    labels_percentage = 0
    authority.issues.each do |issue|
      issue.labels.each do |label|
        if ['quick fix'].include?(label.name)
          labels_percentage += 30
        elsif ['reported', 'council website good'].include?(label.name)
          labels_percentage += 10
        elsif ['anti scraping technology', 'blocked by authority', 'new scraper needed'].include?(label.name)
          labels_percentage -= 30
        end
      end
    end
    activity_factor = Math.sqrt(authority.median_per_week || 0.001) * ACTIVITY_FACTOR

    factors = {
      population: population_factor&.round,
      days_broken: days_broken_factor.round,
      activity: activity_factor.round,
    }

    score = factors.values.compact.sum
    score += (score * labels_percentage.clamp(-60, 50) / 100.0).round
    factors[:labels_percentage] = labels_percentage

    puts "Authority #{authority.name} (#{authority.short_name}) has a score of #{score} from: #{factors.inspect}"
    score
  end

  def self.calculate_scraper_score(scraper)
    broken_authorities = scraper.authorities.active.where(possibly_broken: true)
    base_score = broken_authorities.sum(:broken_score)

    # 10% boost per additional broken authority to incentivize fixing scrapers that address multiple issues
    multiplier = 1 + (0.1 * (broken_authorities.count - 1))

    score = (base_score * multiplier).round
    puts "Scraper #{scraper.name} has a score of #{score} from #{broken_authorities.count} broken authorities with sum #{base_score}"
    score
  end
end
