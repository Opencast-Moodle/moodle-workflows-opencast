# moodle-workflows-opencast
The repository contains *GitHub Actions workflows*, that are reused by the other repositories.

## Test Types

We now support two test types: **Legacy Tests** and **JWT Tests**.

### Legacy Tests

Legacy tests continue to follow the existing workflow test scenarios. No changes are required for plugins that only use legacy tests.

A new workflow parameter is available to control whether legacy tests should be executed:

* `perform-legacy-tests` (default: `true`)

Legacy tests will always run unless this parameter is explicitly set to `false`.

### JWT Tests

To enable JWT-specific tests, several prerequisites must be met.

#### Workflow Configuration

If your plugin contains JWT-specific tests, you must set the `perform-jwt-tests` parameter to `true` when calling the CI workflow:

```yaml
jobs:
  call-moodle-ci-workflow:
    uses: Opencast-Moodle/moodle-workflows-opencast/.github/workflows/moodle-ci.yml@main
    with:
      perform-jwt-tests: true # Required
      requires-block-plugin: true # For Example, change based on your need.
      branch-block-plugin: main   # For Example, change based on your need.
```

#### Plugin Configuration

To ensure tests are recognized as JWT tests, follow the guidelines below.

##### PHPUnit Tests

PHPUnit tests are distinguished by the `TEST_TYPE` environment variable, which is set to either `legacy` or `jwt`.

To simplify this check, the `tool_opencast` plugin provides the `tool_opencast_test_type_helper` class with the following helper methods:

* `is_legacy_test()`
* `is_jwt_test()`

JWT-specific tests should verify the test type during setup and skip execution when the current test run does not match the intended test type.

Example:

```php
public function setUp(): void {
    parent::setUp();

    if (!tool_opencast_test_type_helper::is_jwt_test()) {
        $this->markTestSkipped(
            'Skipping JWT test because the current test type is not JWT.'
        );
    }
}
```

##### Behat Tests

For Behat tests, simply add the `@opencast_jwt_test` tag to the feature file:

```gherkin
@opencast_jwt_test
Feature: JWT authentication
```

The `test-jwt` workflow job automatically discovers and executes all Behat tests tagged with `@opencast_jwt_test`.
