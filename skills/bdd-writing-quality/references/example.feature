# Example: Well-written BDD specification
#
# This file demonstrates what a good Gherkin spec looks like in practice.
# Key qualities to notice:
#   - concrete inputs and outputs, not abstract placeholders
#   - one action per scenario (the "When" step)
#   - observable outcomes only — no implementation internals
#   - error messages are specified, not just "an error occurs"
#   - background used only for state truly shared by every scenario
#   - edge cases and error paths covered alongside the happy path

Feature: Record retrieval
  As a client of the record store
  I want to retrieve records by identifier
  So that I can access stored data reliably

  Background:
    Given the record store contains 100 records
    And record "abc-123" exists with status "active"

  Scenario: Retrieve an existing record
    When the client requests record "abc-123"
    Then the response contains the record with identifier "abc-123"
    And the record status is "active"

  Scenario: Request a record that does not exist
    When the client requests record "does-not-exist"
    Then the request fails with NotFoundError
    And the error message includes "does-not-exist"

  Scenario: Request with an empty identifier
    When the client requests a record with an empty identifier
    Then the request fails with ValidationError
    And the error message includes "identifier must not be empty"

  Scenario: Retrieve the same record twice returns identical content
    When the client requests record "abc-123" twice in sequence
    Then both responses contain identical content

  Scenario: Record at the boundary of valid identifier length
    Given a record exists with the longest permitted identifier
    When the client requests that record
    Then the response contains the record without error

  Scenario: Request a record with an identifier that exceeds the maximum length
    When the client requests a record with an identifier of 256 characters
    Then the request fails with ValidationError
    And the error message includes "identifier too long"


Feature: Configuration validation
  As the application entry point
  I want to validate configuration before startup
  So that misconfigured runs fail immediately with a clear message

  Scenario: Accept a complete valid configuration
    Given a configuration with all required fields set to valid values
    When the configuration is validated
    Then validation passes
    And no warnings are emitted

  Scenario: Reject a configuration missing a required field
    Given a configuration with "output_path" omitted
    When the configuration is validated
    Then validation fails
    And the error message includes "output_path"
    And the error message includes "required"

  Scenario: Reject a configuration containing an unknown field
    Given a configuration containing the unknown field "ouput_path"
    When the configuration is validated
    Then validation fails
    And the error message includes "ouput_path"
    And the error message includes "unknown field"

  Scenario: Reject a numeric field set to an out-of-range value
    Given a configuration with "max_retries" set to -1
    When the configuration is validated
    Then validation fails
    And the error message includes "max_retries"
    And the error message includes "must be a positive integer"

  Scenario: Report all validation errors at once, not just the first
    Given a configuration missing "output_path" and "timeout_seconds"
    When the configuration is validated
    Then validation fails
    And the error message includes "output_path"
    And the error message includes "timeout_seconds"

  Scenario: Reject an empty configuration file
    Given an empty configuration file
    When the configuration is validated
    Then validation fails
    And the error message includes "configuration is empty"
