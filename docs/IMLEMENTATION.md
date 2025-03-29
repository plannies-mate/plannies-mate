# Plannies-Mate Implementation

See Also:

- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate)

Note: README.md is for setup and usage by the Developer

## Architecture

### Directory Structure and Content Flow

1. Source Content Structure (in roles/web/files/):

```
plannies-mate/
├── app/          # Sinatra App and Rake tasks
│   ├── contents/       # Raw content to be themed
│   │   ├── authorities/defaut.html
│   │   ├── crikey-whats-that/index.html
│   │   ├── errors/ Error pages
│   │   ├── index.html
│   │   ├── issues/default.html
│   │   └── scrapers/default.html
│   ├── controllers/ - Sinatra controllers
│   ├── fetchers/ - Fetch content from external resouces and present in Array/Hash format
│   ├── generators/ - Generators of static html pages from database
│   ├── helpers/ - View and Processing helpers
│   ├── importers/ - Updates DB from external fetched data or direct (github Api)
│   ├── lib/ - misc library files
│   ├── matchers/ - Matches data from different external sources
│   ├── models/ - DB models / tables for background tasks
│   ├── services/ - Misc services for specific algorithms
│   ├── tasks/ - rake tasks
│   └── views/ - Slim templates for pages
│       ├── layouts - layouts for views (no-menu, with-menu and favicob-*)
│       └── partials - Partials that are included into pages
├── app.rb - requires all the files needed for sinatra app
├── config/ - boot and database configuration files
├── config.ru - RackUp configuration for app
├── db/
│   ├── ENVIRONMENT.sqlite3 - database files
│   ├── migrate - migration files
│   ├── pull_requests.yml - Manually entered pull requests
│   ├── schema.rb - auto generated - used by db:create if present
│   └── seeds.rb - seed data (currently none)
├── Gemfile* - List of gems for project (with app and task sub sections)
├── Gemfile.lock
├── GUIDELINES.md - AI guidelines
├── IMLEMENTATION.md - Project wide implementation details (class level details are part of YARD docs)
├── lib/
├── LICENSE
├── public/          # Static files copied directly to web root
│   │   ├── css/        
│   │   ├── js/         
│   │   └── images/     
│   ├── favicon.ico
│   └── robots.txt
├── Rakefile - Configuration for rake
├── README.md - Developers how to use starting point
├── script/ - Scripts to rule them all, github style
├── spec/ - Rspec test by exmple
├── SPEC.md - Specification
└── tasks.rb - requires all the files needed for rake tasks


```

2. Build Process
    - add_theme program:
        - Reads content from
            - roles/web/files/contents/
            - ../plannies-mate/log/contents/
        - Applies layout from roles/web/files/layouts/
        - Outputs to tmp/build/ maintaining directory structure

3. Web Root Structure (/var/www/html):

```
/var/www/html/
├── assets/          # Copied directly from roles/web/files/assets
├── authorities/     # Themed content from tmp/build/authorities
├── repos/          # Themed content from tmp/build/repos
└── crikey-whats-that/     # Themed content from tmp/build/crikey-whats-that
```

### Content Management

1. Theme System
    - layouts support substitution of:
        - {{TITLE}} and {{CONTENT}} from contents file
        - {{FAVICON}} and {{SECTION}} for crikey-whats-that or default
        - {{LAST_CHECKED}} which indicates the freshness of the plannies-mate contents file
          or time deployed for the other contents
    - Theme applied during build, not runtime
    - Default layout provides standard header/footer
    - Error pages follow same theming

2. Content Updates
    - Ansible copies assets directly
    - Themed content copied from tmp/build/
    - Maintains separation between raw and themed content in the repos (themed content is not committed to git)

#### Theme Notes

- Uses Font Awesome icons via CDN
- Uses Topography pattern from heropatterns.com for subtle background texture
- Uses Green and gold Australian color scheme
- Landing page is a clean bold design with a splash of fun, whilst being informative
- Everything else continues the theme but is focused on being useful to me and my fellow co-workers
- Whimsical Aussie wording and phrasing, with the typical Aussie not taking ourselves too seriously
    - Despite this, Usefulness and clarity is TOP priority


## Dependencies

Fail fast with message if missing where required for processing:

- Ruby 3.2.3 (default on Ubuntu 24.04 Noble)
- Ansible
- Git
- Required gems
- Linode API access
- Github OAuth2 App for authentication
- Gems listed in Gemfile

### Resources

* Consider https://listjs.com/ for table sorting and filtering

## APP Service Implementation

### Architecture

1. Lightweight Sinatra APP
    - Html pages using slim to allow roundup status to be reported and processing to be requested (/app/roundup)
    - Runs on localhost:4567
    - Minimal gem dependencies
    - File-based state management
    - Protected behind OAuth2-Proxy

2. State Management
    - Uses sqlite3 database and activerecord in /var/www/app/db/productioin.sqlite3
    - trigger_scrape file for on-demand processing

3. Background Processing
    - Ruby script executed via cron
      - Generates html static pages
    - Daily scheduled run at midnight
    - Checks every 15 minutes for triggers
    - Simple log rotation approach
    - Stateless execution model

### Integration Points

1. Caddy Configuration
    - /app endpoints proxied to OAuth2-Proxy for authentication
    - OAuth2-Proxy proxies /app to Sinatra
    - No direct external access

2. Authentication Flow
    - Users authenticated via OAuth2-Proxy
    - No additional auth required for API
    - both GET and POST endpoints protected by same OAuth flow

### Resource Usage

- Memory: ~40MB for Sinatra process
- CPU: Low, except during analysis
- Disk: Minimal for logs and state files
- Caddy, OAuth2-proxy and plannies-app services are restarted between 3AM and 4AM AEST to mitigate any memory leaks
- Squid is gracefully reloaded around the same time

### App Development

Run

* `bin/app server` for api server
* `bin/app rake -T` to list tasks available


## Testing Philosophy:

* Test against reality, not what we think it should be!
    * Use VCR for external API calls instead of mocking
    * Use real components unless there's a compelling reason to mock
* Keep tests under 200 lines by splitting into multiple focused files
* Use appropriately named subdirectories when splitting test files - rubymine expects `SomeClass` to be tested using
  `some_class_spec.rb` but allows multiple files in differently named sibling directories.

## Code Organization Principles:

* Split large files into focused components (< 200 lines)
* use extend with Helper Modules and `class InstanceMethods ... end` and `send :include, InstanceMethods` within the
  helper module for those methods that require access to instance state. This unfortunately means that many helper
  methods need to be accessed using `self.class.method_name` but we sometimes need to access them from class methods.

## Gathering information from GitHub

Use https://docs.github.com/en/rest/guides/scripting-with-the-rest-api-and-ruby

* [Authentication as a GitHub App](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app)
* https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api
*  wait at least one second between each request

## CSS Styling

1. The CSS changes introduce three container styles:
   - .container (max-width: 1200px) - Good for detail pages and standard content
   - .wide-container (max-width: 1900px, width: 95%) - Better for list pages with wide tables
   - .responsive-container (width: fit-content, min-width: 80%, max-width: 95%) - Adjusts based on content

2. The table styles have been enhanced to:
   - Add .nowrap class to prevent awkward line breaks in certain cells
   - Improve header styling with sticky positioning
   - Add .limit-width class for cells that should truncate with ellipsis
   - Add word break opportunities with the add_word_breaks helper

3. The templates have been updated to use the appropriate container classes
   - List pages (authorities.html.slim and scrapers.html.slim) use .wide-container
   - Detail pages (authority.html.slim and scraper.html.slim) use .container

