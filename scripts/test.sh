#!/usr/bin/env bash

set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "${script_dir}/load-prepare.sh" test

# Copy user-supplied CLI args into a mutable array
test_args=( "$@" )

test_runner_id=$(( RANDOM % 10000 + 1000 ))

# Determine if we should skip building
skip_build=""
if [[ -n "${BUILDKITE:-}" ]]; then
  # In CI, always skip build since prepare.sh handles it
  skip_build="--skip-build"
  test_args+=( --scratch-path .spm-cache )
elif [[ -d ".build" ]]; then
  # Locally, skip build if .build directory exists
  skip_build="--skip-build"
fi

# Create test results directory
mkdir -p test-results

# Add test output options for BuildKite
if [[ -n "${BUILDKITE:-}" ]]; then
  test_output_path="test-results/test-${test_runner_id}"
  test_args+=( --parallel --xunit-output "${test_output_path}.xml" )
fi

# Run tests and capture exit code
test_exit_code=0
if [ ${#test_args[@]} -eq 0 ]; then
  echo "Running tests: swift test ${skip_build}"
  swift test ${skip_build} || test_exit_code=$?
else
  echo "Running tests: swift test ${skip_build} ${test_args[*]}"
  swift test ${skip_build} "${test_args[@]}" || test_exit_code=$?
fi

# Strip ANSI color codes from XML files if in CI
if [[ -n "${BUILDKITE:-}" ]]; then
  echo "Cleaning ANSI codes from test result XML files..."
  for xml in test-results/*-swift-testing.xml; do
    if [[ -f "$xml" ]]; then
      # Remove ANSI escape sequences using sed
      sed -i '' $'s/\x1b\\[[0-9;]*m//g' "$xml"
      echo "Cleaned: $xml"
    fi
  done
fi

# Exit with the same code as the tests
exit $test_exit_code
