Feature: Download State
  As a user
  I want to track download history
  So that I can monitor archived content

  Background:
    Given a storage directory exists
    And a download manager is created

  Scenario: Download history tracks entries
    When I download "http://example.com" using mock strategy "single_page"
    Then the download history shows 1 entry
    And the download state is "done"

  Scenario: Multiple downloads are tracked
    When I download "http://example1.com" using mock strategy "single_page"
    And I download "http://example2.com" using mock strategy "single_page"
    Then the download history shows 2 entries
    And each download state is "done"