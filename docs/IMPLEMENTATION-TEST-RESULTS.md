# Test Results Implementation

This document outlines the implementation strategy for tracking and reporting morph.io test results for scrapers and
their associated pull requests.

## Database Structure

We'll need to add SHA fields to the existing PullRequest model and create two new tables:

1. **Update PullRequest model**:
    - Add `head_sha` - SHA of the head commit in the PR
    - Add `base_sha` - SHA of the base commit the PR is against

2. **TestResult model**:

    - contains MY test results (not production nor anyone else's)
    - Links to the scrapers (`scraper_id`)
    - Test details:
        - `name` - the name of the repo (which is often the scraper plus branch on the official fork)
        - `git_sha` - Commit SHA being tested
        - `status` - Run status (passed/failed/running)
        - `run_at` - Timestamp when the test was run
        - `duration` - How long the test took
        - `records_added` - Number of records added
        - `records_removed` - Number of records removed
        - `error_message` - Overall error message (if any)

3. **AuthorityTestResult model**:

    - Links to `test_result_id` and `authority_id`
    - `status` - Status for this authority (successful/failed/interrupted)
    - `record_count` - Number of records found for this authority
    - `error_message` - Specific error for this authority (if any)

4. **`config/authority_label_map.yml` file**

- Provides a cross-link between an authority_label in the data table and the authority short name - most are a 1:1
  mapping, but this config table lists the exceptions, containing a list of:

```yaml
- authority_label: new_name
  short_name: authority_short_name
```

## Import Process

1. **MorphIoFetcher class**:
    - Retrieve the list of test scrapers from morph.io
    - Fetch test run details for each scraper
    - Extract per-authority results from scrape_summary or data tables

2. **TestResultsImporter class**:
    - Process data from the fetcher
    - Store results in the database
    - Link authorities based on authority_label
    - Find matching PRs by commit SHA

## Static Page Generation

1. **TestResultsGenerator class**:
    - Generate an index page listing all test results
    - Group by scraper and status
    - Include links to detailed test pages

2. **TestResultGenerator class**:
    - Generate a detailed page for each test result
    - Show per-authority status
    - Link to matching PRs with the same commit SHA

3. **Update existing generators**:
    - Add PR status to authority and scraper pages
    - Add test result links to PR pages

## PR Status Logic

For each PR, we'll determine its status based on test results:

- **Bad** (red): PR fails for authorities that worked in production
- **Good** (green): PR fixes one or more authorities while keeping existing ones working
- **Meh** (medium gray): PR doesn't change the list of working authorities
- **Untested** (dark yellow): No test results with matching commit SHA

## File Changes

### New Files

- `db/migrate/YYYYMMDDHHMMSS_add_sha_to_pull_requests.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_test_results.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_authority_test_results.rb`
- `app/fetchers/test_results_fetcher.rb`
- `app/importers/test_results_importer.rb`
- `app/generators/test_results_generator.rb`
- `app/generators/test_result_generator.rb`
- `app/models/test_result.rb`
- `app/models/authority_test_result.rb`
- `app/views/test_results.html.slim`
- `app/views/test_result.html.slim`

### Updated Files

- `app/views/partials/authority_row.html.slim`
- `app/views/partials/authority_header.html.slim`
- `app/views/partials/scraper_row.html.slim`
- `app/views/pull_request.html.slim`
- `app/tasks/import.rake`
- `app/tasks/analyze.rake`
- `app/tasks/generate.rake`

## Implementation Approach

We'll implement this feature using an incremental approach:

1. Add migrations and update models first
2. Implement the TestResults fetcher and importer
3. Create the test results generators
4. Update existing generators to include PR status information
5. Test with actual morph.io data

This approach aligns with the project's preference for clarity, simplicity, and incremental improvements.
