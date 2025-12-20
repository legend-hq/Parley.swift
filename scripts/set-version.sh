#!/bin/bash
set -euo pipefail

git_root=$(git rev-parse --show-toplevel)

target_version=${1:-}

function print_usage() {
  >&2 printf "Usage: set-version.sh <version>\n"
}

if [[ -z "${target_version}" ]]; then
  >&2 printf "‼ Missing version\n"
  print_usage
  exit 1
fi

charter="${git_root}/Parley.swift/Sources/Charter/Charter.swift"

sed -i.bak -Ee \
  "s/public static let version = \".*\"/public static let version = \"${target_version}\"/" \
  "${charter}"

if grep -q "public static let version = \"${target_version}\"" "${charter}"; then
  printf "✓ Updated Parley.swift Charter version to %s.\n" "${target_version}"
  rm ${charter}.bak
else
  >&2 printf "✗ Failed to update Parley.swift Charter version to %s.\n" "${target_version}"
  mv ${charter}.bak ${charter}
  exit 1
fi
