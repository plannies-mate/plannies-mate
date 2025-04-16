TESTING WITH MORPH.IO
=====================

Background
----------

* morph.io will only test the default branch of public repos.
* The multiple_* scrapers ("multis") are private repos, so forks in GitHub are also private.
* Custom scrapers (for one authority) are normally public anyway
* I create an empty public repo with the name <scraper>-<branch> for multis
  where <branch> is a branch in my private fork I will generate a PR from.
* I push the branch I want tested to the master branch of a public repo and
  register that public repo with moprh.io.
* I set MORPH_AUSTRALIAN_PROXY and MORPH_EXPECTED_BAD (so it won't complain
  about authorities I expect to fail), and set it to auto-run.

https://morph.io/ianheggie-oaf lists scrapers under test, eg: currently 4 scrapers, the first being

* name: multiple_civica-prs (links to detail page)
* language: Ruby (which means it has scraper.rb)
* auto_run: true
* status:
    * errored: true (which means the last run failed)
    * running: if pulsing icon is present
    * passed: passed last test
* description: Test All civica pull requests (repeat of github repo description - not important)

Detail page includes:

History, with status of each run and links to commit versions, eg:
```
Auto ran revision 7f90e82c and failed about 3 hours ago.
run time about 2 hours
1620 records added, 1494 records removed in the database

Manually ran revision 7f90e82c and failed about 12 hours ago.
run time about 2 hours
1667 records added in the database
```

For multiples using scraper_utils it will include the `scrape_summary` table, containing rows like:

* run_at: 2025-04-15T22:40:57+00:00
* attempt: 1
* duration: 5684.8
* successful: albury,ballina,bega_valley,broken_hill,bundaberg,byron,cessnock,dubbo,fairfield,gympie,lismore,muswellbrook,port_macquarie_hastings,port_stephens,strathfield,upper_hunter
* failed: bogan,burwood,griffith,gunnedah,shoalhaven,singleton
* interrupted: maranoa
* successful_count: 16
* interrupted_count: 1
* failed_count: 8
* public_ip:

using:

```sql
SELECT * 
FROM scrape_summary 
ORDER BY run_at desc 
WHERE run_at >= #{7.days.ago} 
```

Otherwise, you will need to query the data table:

```sql
SELECT date_scraped, authority_label, count(*) 
FROM data 
GROUP BY 1,2
ORDER BY date_scraped dsec, authority_label 
WHERE date_scraped >= #{7.days.ago} 
```

Checking a PR
-------------

The test for a PR (a recent morph test with the same commit sha as the PR)

* MUST have all the authorities that work in production also working in the test
* MUST have the identified authority working
* MAY have additional authority working that production does not
* MUST have the same git commit as the PR
* It is acceptable that the test has MORPH_AUTHORITIES set to '!BAD' (which inverts MORPH_EXPECT_BAD) - feature to be added 

Currently, I am submitting individual PR's, but testing "prs" branch which is a merge of the lot.

Changes to My Pull Requests
--------------------------

The [pull requests index](https://plannies-mate.thesite.info/pull_requests) 
will be split into:

* My Open Pull Requests
* My Merged Pull Requests
* My Closed Pull Requests

New "Test Results" menu option
------------------------------

The Test results index wil list the results from https://morph.io/ianheggie-oaf with 
an additional "Status" (same as PR status, but for whatever the latest commit is)  

The details page eg `/test_results/my_repo_name` (eg multiple_civica-prs) 
will be similar to the existing authorities list for a scraper, but include additional info:

It will include:

* The test run (Pass, Fail, Interrupted (counted as fail for the authorities report))
* The number of records found for the Authority (in the test run)
* The error message

* And link to any PR's with the same full git commit

Change to Authority Row in authorities and scrapers pages
---------------------------------------------------------

Add after "Issues" a "PR status" which reports WHEN THERE IS a PR one of:

* "Worse" (red) - fails one of the existing working authorities
* "Good" (green) - fixes one of more authorities and keeps the existing ones running
* "Meh" (gray) - doesn't improve the list of working authorities
* "Untested" (colour?) - hasn't tested the git commit for the PR

These will be a link to a /pull_request/scraper/number.html 

If there are multiple PR's then multiple status's are listed

Note:

* a PR may be related to another scraper, for example
  when an authority moves between scrapers there will be two PR's -
  deleting from one and adding to another scarper.

DISCUSS
=======

* Should I bother working out what branches are merged into a combined branch like "prs"??
  After all it has been tested as a unit and doesn't really indicate if the individual PRs should be merged.
  * Conclusion: Have individual PR's tested individually.

* Import strategy, and tables to be created to support the generation of these reports

