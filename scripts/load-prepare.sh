#!/bin/bash

set -euo pipefail

# script_dir is not used in this script
env=${1:-test}
# In CI, use agent-specific artifact name to avoid PCH path conflicts
if [[ -n "${BUILDKITE:-}" ]] && [[ -n "${BUILDKITE_AGENT_NAME:-}" ]]; then
  artifact_file="artifact_${env}_agent_${BUILDKITE_AGENT_NAME}.tar.gz"
else
  artifact_file="artifact_${env}.tar.gz"
fi

if [ -n "${BUILDKITE:-}" ]; then
  echo "Loading build artifacts..."
  # Download any artifact matching the pattern (could be from any agent)
  buildkite-agent artifact download "artifact_${env}*.tar.gz" . --step "prepare_${env}_build"

  # Extract the first (and should be only) matching archive
  artifact_found=$(ls artifact_${env}*.tar.gz 2>/dev/null | head -n1)
  if [ -n "$artifact_found" ]; then
    echo "Extracting $artifact_found"
    tar -xzf "$artifact_found"
  else
    echo "ERROR: No artifact found matching artifact_${env}*.tar.gz"
    exit 1
  fi
else
  # In local development, this is a no-op
  # Swift will handle building if needed when --skip-build is omitted
  :
fi
