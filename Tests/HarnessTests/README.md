# Harness Tests

Harness Tests are integration tests copied directly from the admin dashboard for Quark intents. These tests allow you to reproduce issues from stage/prod in a controlled local environment.

## Running Tests

Run all harness tests:

```sh
swift test --filter HarnessTests
```

Run a specific harness test:

```sh
swift test --filter HarnessTests.Harness_Test_Dev_QuarkIntent_289
```

## Test Structure

Tests are defined in `HarnessTests.json` and loaded at runtime. Each test contains:

- **name**: Test identifier (e.g., `Harness_Test_Prod_QuarkIntent_298`)
- **mercator_version**: The Charter version this test was created for
- **intent**: The QuarkIntent being tested
- **chart**: Expected Chart output (optional)
- **chart_user**: Expected Chart output from user perspective (optional)
- **folio**: Portfolio state including balances, prices, and rewards

## Version Filtering

Tests only run when their `mercator_version` matches the current `Charter.version`. Tests with version mismatches are automatically filtered out and logged in yellow during test execution.

This ensures tests remain valid after version changes, as older tests are very likely to fail when the QuarkIntent version changes.

## Adding New Tests

Copy test data from the admin dashboard for a Quark intent and add it to `HarnessTests.json` in the array of tests. The test will automatically be discovered and executed by the test suite.