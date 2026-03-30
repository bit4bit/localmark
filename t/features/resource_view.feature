Feature: Resource View
  As a user
  I want to view downloaded resources
  So that I can read archived content

  Background:
    Given a storage directory exists
    And a site "test-package/hello" with resource "/index.html" containing html content

  Scenario: View existing resource
    When I request the site "test-package" "hello" resource "/index.html"
    Then the response is successful
    And the response contains html content

  Scenario: View resource with .html suffix fallback
    When I request the site "test-package" "hello" resource "/index"
    Then the response is successful
    And the response contains html content

  Scenario: View non-existent resource
    When I request the site "test-package" "hello" resource "/nonexistent.html"
    Then the response status is 404

  Scenario: View non-existent package
    When I request the site "missing" "site" resource "/index.html"
    Then the response status is 404