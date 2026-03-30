Feature: Resource Annotate
  As a user
  I want to add comments to resources
  So that I can annotate my archived content

  Background:
    Given a storage directory exists
    And a site "docs/notes" with resource "/doc.html" containing html content

  Scenario: Add comment to resource
    When I add comment "First note" to resource "/doc.html" in site "notes" package "docs"
    Then the resource "/doc.html" in site "notes" package "docs" has comment "First note"

  Scenario: Update comment creates new version
    Given the resource "/doc.html" in site "notes" package "docs" has comment "First"
    When I add comment "Second" to resource "/doc.html" in site "notes" package "docs"
    Then the resource "/doc.html" in site "notes" package "docs" shows comment "Second"

  Scenario: View site shows latest comment
    Given the resource "/doc.html" in site "notes" package "docs" has comment "Important"
    When I request the site "docs" "notes"
    Then the response is successful
    And the response contains the text "Important"