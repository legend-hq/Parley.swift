#!/bin/bash
set -euo pipefail

swiftly=$(command -v swiftly || command -v "${HOME}/.swiftly/bin/swiftly")

git_root=$(git rev-parse --show-toplevel)

target_dependency=${1:-}

if [[ -z "${target_dependency}" ]]; then
  >&2 printf "‼ Missing target dependency identity.\n"
  >&2 printf "Usage: get-dep-version.sh <target-dep>\n"
  exit 1
fi

# lowercase the target_dependency
target_dependency=$(tr '[[:upper:]]' '[[:lower:]]' <<< "${target_dependency}")
# strip trailing .swift if any
target_dependency=${target_dependency%%.swift}

${swiftly} run swift package                \
  --package-path ${git_root}/Mercator.swift \
  describe                                  \
  --type json                               \
| jq -r ".dependencies | .[] | select(.identity == \"${target_dependency}.swift\") | .requirement.exact[0]"
