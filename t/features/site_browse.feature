Feature: Site Browse
  As a user
  I want to browse and search downloaded sites
  So that I can find and view archived content

  Background:
    Given a storage directory exists

  Scenario: List all sites
    Given a package "pkg1" with site "site1"
    And a package "pkg1" with site "site2"
    And a package "pkg2" with site "site3"
    When I request the homepage
    Then the response is successful
    And I see 3 sites

  Scenario: Filter sites by package
    Given a package "perl" with site "moose"
    And a package "python" with site "django"
    When I request the homepage with filter_package "perl"
    Then the response is successful
    And I see only sites from package "perl"

  Scenario: Search sites by content
    Given a site "searchable" in package "test" with resource "/a.html" containing "hello world"
    And a site "other" in package "test" with resource "/b.html" containing "goodbye"
    When I request the homepage with filter_content "hello"
    Then the response is successful
    And I see only site "searchable"

  Scenario: Site with description
    Given a site "documented" in package "docs" with description "Important docs"
    When I request the site "docs" "documented"
    Then the response is successful
    And the response contains "Important docs"

  Scenario: Site comments
    Given a site "notes" in package "test" with resource "/doc.html" containing html content
    When I add comment "First note" to the site resource "/doc.html"
    And I request the site "test" "notes"
    Then the response is successful
    And the response contains the text "First note"