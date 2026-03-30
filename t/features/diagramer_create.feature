Feature: Diagramer Create
  As a user
  I want to create PlantUML diagrams
  So that I can visualize my documentation

  Background:
    Given a storage directory exists

  Scenario: View diagramer page
    When I request the diagramer page
    Then the response is successful

  Scenario: Submit PlantUML code
    When I submit PlantUML code to the diagramer:
      """
      ClassA o-- ClassB
      """
    Then the response is successful
    And the response contains diagram output