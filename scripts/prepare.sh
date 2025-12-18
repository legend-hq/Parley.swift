#!/bin/bash

set -euo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
env=${1:-test}

# In CI, make artifact name agent-specific to avoid PCH path conflicts
if [[ -n "${BUILDKITE:-}" ]] && [[ -n "${BUILDKITE_AGENT_NAME:-}" ]]; then
  artifact_file="artifact_${env}_agent_${BUILDKITE_AGENT_NAME}.tar.gz"
else
  artifact_file="artifact_${env}.tar.gz"
fi

# Use local disk cache for fast access when running multiple swift test commands
# This avoids rebuilding when tests run sequentially on the same machine
tmp_dir="/tmp/Mercator"
mkdir -p "$tmp_dir"
tmp_file="$tmp_dir/$artifact_file"

if [ -f "$tmp_file" ]; then
  echo "Temp cache exists. Extracting..."
  tar -xzf "$tmp_file"
else
  echo "Temp cache '${artifact_file}' not found; skipping extraction."
fi

compile_args=()
# In CI, put the build cache in a deterministic folder we can restore
if [[ -n "${BUILDKITE:-}" ]]; then
  compile_args+=( --scratch-path .spm-cache )
fi

"$script_dir/setup-swift.sh"

# Pass compile args if any exist
if [ ${#compile_args[@]} -eq 0 ]; then
  "$script_dir/compile-tests.sh"
else
  "$script_dir/compile-tests.sh" "${compile_args[@]}"
fi

if [ -n "${BUILDKITE:-}" ]; then
  echo "Uploading to buildkite to artifact and temp cache"

  tar -czf "$artifact_file" .spm-cache
  buildkite-agent artifact upload "$artifact_file"
  cp "$artifact_file" "$tmp_file"
fi
