# Plannies Mate - Tasks Specifications

See Also:

- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate)
- IMPLEMENTATION.md - implementation decisions made
- SPECS.MD - Project wide specs

Note: README.md is for setup and usage by the Developer

The main purpose of the rake tasks is to generate html content in site_dir:

* /var/www/html - Production environment
* project_dir/tmp/html - Development environment
* project_dir/tmp/html-test - Test environment

## Periodic Cron jobs

* `roundup:all` is run nightly
* `roundup:if_needed` is run each 30 minutes

## Import tasks

These tasks import data from external resources:

* `import:authorities` - imports using fetchers from https://www.planningalerts.org.au/authorities and linked authority
  detail and "under the hood" (stats) pages into Authority and Scraper tables. Fetchers extract the data from the
  html pages.

* `import:issues` - imports [Issues](https://github.com/planningalerts-scrapers/issues/issues) using github API into
  Issue, User and IssueLabel tables

* `import:pull_requests` - imports the pull requests I created
  targeting [planningalerts-scrapers repos](https://github.com/orgs/planningalerts-scrapers/repositories?q=archived%3Afalse)
  using github API into the PullRequest table and sets up associations

* `import:coverage_history` - Imports historical coverage stats using the WayBack archive of authorities index into
  CoverageHistory table. Requires PullRequest.authorities association to have been populated (automatically for single
  authority repos, manually for non-obvious multis - branch name may match an authority or pull request title may
  contain authority name or short_names)

To consider:

* `import:branches` - imports the branches of repos from [my repos](https://github.com/ianheggie-oaf?tab=repositories)
  whose repos are forks of some of the planningalerts-scrapers repos
  * Also adds webhooks to be informed of branches and pull requests
  * /webhooks should be sent directly to sinatra app by caddy rather than going through Oauth2 Proxy

## Tasks to Generate html website

These tasks rely on import tasks being run

* `generate:public` - copies `project_dir/public` to `site_dir`
* `generate:content` - inserts html files from `app/contents` into default layout (or no-menu for base index.html)
  and writes to `site_dir`
* `generate:authorities` - Generate Authorities index page: `site_dir/authorities.html`
* `generate:authority_pages` - Generate individual authority pages: `site_dir/authorities/AUTHORITY.html`
* `generate:scrapers` - Generate scrapers index page: `site_dir/scrapers.html`
* `generate:scraper_pages` - Generate individual scraper pages: `site_dir/scrapers/SCRAPER.html`
* `generate:coverage_history` - Generate coverage history report: `site_dir/coverge_hostory.html`

To consider:

* generate a maintenance_required.html (login required) list - include:
  * interesting branches that don't have pull requests - prompts me to create pull requests
  * branches that have merged pull requests (can be deleted locally and on github)

## The Big Picture

Why do I care and what will I use these for!?

### Scrapers

I can see the state of each of the scrapers, what authorities are broken and if there is a Pull request with a fix or if
someone else is working on the issue.

Need a clear visual:

* Nothing for me to do (not broken, I made a PR, someone else is working on it) - Pale Green background?
* Assigned to me to work on - Yellow background?
* Consider to work on (Combined with Scrapers listed in order of most broken to least ordered by population affected *
  log2(months down))

* `site_dir/scrapers.html` - list of scrapers with a table of the associated authorities grouped under each
  class: `lib/scrapers_generator.rb`
* `site_dir/scrapers/scraper_name.html` - details of scraper (currently just the github and auth links and a list
  of
  authorities that use the scraper)
  class: `lib/scraper_generator.rb`

Repos Index is grouped by

* h1. Multi / Custom / Unused
* h2. Scraper (in order of score for multi)

The Multis are their own H2 headings. The Custom (single authority related to one scraper) are all in one table. The
Unused will be the scrapers we find from github that are not mentioned on any authority details page.

Links (can be a terse list of links):

* github: "repo", PR link, issue numbers, status (In Progress etc), tags listed beside
* morph: production, ianheggie-oaf (if available)
* info - links to a detailed page for each authority

#### Scrapers Details page

The details page should also include feedback on how my work on broken scrapers is progressing... (TBD)

### Authorities

Mainly as a enhanced version of authority coverage?

* `site_dir/authorities.html` - table of authorities with scraper and detail relative links - order by authority
  class: `lib/authorities_generator.rb`
* DISCUSS if we generate different pages for different sort orders, or use a javascript plugin to sort the table (prefer
  as we will later also add filtering)
* `site_dir/authorities/short_name.html` - detailed page for each authority listing all the details we have
  class: `lib/authority_generator.rb`

* table of authorities in order of score within scraper, listing
    * authority name
    * state
    * population
    * months down (if down) otherwise blank if up
    * production month count
    * spec count (expected records in spec if updated since scraper went down)
    * test count (records from Ian's run of scraper)

### Has a site changed to something an existing scraper already handles?

This is the focus of the "Crikey, Whats That!?" sub-project - extracting significant search strings from each of the
repos to find which scraper best matches a sites new search results page.

### Coverage History

this is basically to showcase the impact my work has as well as to gain an understanding of the size of the work (how
quickly scraping of authorities break)
