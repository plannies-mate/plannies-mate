# frozen_string_literal: true

# Service for synchronizing pull requests between YAML and database
class PrSyncService
  attr_reader :pr_file_path
  
  def initialize(pr_file_path = nil)
    @pr_file_path = pr_file_path || PrFileService::PR_FILE
    @github_service = GithubPrService.new
  end
  
  # Sync PRs from YAML to database
  def sync_from_yaml
    return { error: "PR file not found: #{pr_file_path}" } unless File.exist?(pr_file_path)
    
    begin
      yaml_data = YAML.load_file(pr_file_path) || []
    rescue => e
      return { error: "Failed to parse YAML: #{e.message}" }
    end
    
    result = PullRequest.import_from_file(yaml_data)
    { success: true, imported: result[:imported], updated: result[:updated] }
  end
  
  # Sync PRs from database to YAML
  def sync_to_yaml
    yaml_data = export_prs_to_yaml
    
    # Save to file
    FileUtils.mkdir_p(File.dirname(pr_file_path)) unless Dir.exist?(File.dirname(pr_file_path))
    File.open(pr_file_path, 'w') { |f| f.write(YAML.dump(yaml_data)) }
    
    { success: true, exported: yaml_data.size }
  end
  
  # Update PR status from GitHub
  def update_from_github(limit = nil)
    # Only update PRs that need updates
    prs = PullRequest.needs_github_update.order(created_at: :desc)
    prs = prs.limit(limit) if limit
    
    updated_count = 0
    not_found_count = 0
    error_count = 0
    
    prs.each do |pr|
      # Skip if we don't have enough GitHub information
      next unless pr.github_owner.present? && pr.github_repo.present? && pr.pr_number.present?
      
      begin
        puts "Checking #{pr.github_owner}/#{pr.github_repo} PR ##{pr.pr_number}..."
        
        data = @github_service.check_pr_status(pr.github_owner, pr.github_repo, pr.pr_number)
        
        # Update PR with data from GitHub
        if pr.update_from_github(data)
          updated_count += 1
          puts "  Updated PR status: #{data['state']}, merged: #{data['merged'] || false}"
        else
          puts "  No status change detected"
        end
      rescue StandardError => e
        if e.message.include?('404')
          not_found_count += 1
          puts "  PR not found on GitHub"
          
          # Mark as checked to avoid future API calls
          pr.update(last_checked_at: Time.now)
        else
          error_count += 1
          puts "  Error checking PR: #{e.message}"
        end
      end
      
      # Be nice to GitHub API
      sleep 1 if prs.size > 1
    end
    
    # Update YAML file with the latest data
    sync_to_yaml if updated_count > 0
    
    {
      checked: prs.size,
      updated: updated_count, 
      not_found: not_found_count,
      errors: error_count
    }
  end
  
  private
  
  # Export PRs to YAML format
  def export_prs_to_yaml
    # Get all PRs and preload authorities
    prs = PullRequest.includes(:authorities).order(created_at: :desc)
    
    prs.map do |pr|
      {
        'title' => pr.title,
        'url' => pr.url,
        'created_at' => pr.created_at.to_date.to_s,
        'closed_at' => pr.closed_at_date&.to_s,
        'accepted' => pr.accepted,
        'pr_number' => pr.pr_number,
        'authorities' => pr.authorities.map(&:short_name)
      }
    end
  end
end
