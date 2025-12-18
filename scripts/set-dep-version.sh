#!/bin/bash
set -euo pipefail

git_root=$(git rev-parse --show-toplevel)

target_dependency=${1:-}
target_version=${2:-}
spec=${3:-exact}

function print_usage() {
  >&2 printf "Usage: set-dep-version.sh <target-dep> <version> [exact|from|branch|revision] (default: exact)\n"
}

if [[ -z "${target_dependency}" ]]; then
  >&2 printf "‼ Missing target dependency name\n"
  print_usage
  exit 1
fi

if [[ -z "${target_version}" ]]; then
  >&2 printf "‼ Missing version\n"
  print_usage
  exit 1
fi

if [[ $(${git_root}/semver.sh validate "${target_version}") == invalid ]]; then
  >&2 printf "‼ Invalid version: %s\n" "${target_version}"
  exit 1
fi

# back up the original Package.swift file
cp ${git_root}/Mercator.swift/Package.swift ${git_root}/Mercator.swift/Package.swift.bak

# edit the dependency version with an ex script, if it works
#
# NOTE: this probably only works when the .package(...) declaration is
# across multiple lines?
#
vim=$(command -v vim || command -v nvim)
${vim} -es ${git_root}/Mercator.swift/Package.swift <<-EOF
  silent /dependencies:
  silent /\.*${target_dependency}
  normal [(
  silent /exact\|from\|branch\|revision
  norm cw${spec}
  norm f"vi"c${target_version}
  wq
EOF

# check our work: if we failed, restore the backup Package.swift file
if [[ $(${git_root}/Mercator.swift/scripts/get-dep-version.sh "${target_dependency}") == "${target_version}" ]]; then
  printf "✓ Updated %s to version %s.\n" "${target_dependency}" "${target_version}"
  rm ${git_root}/Mercator.swift/Package.swift.bak
else
  >&2 printf "✗ Failed to update dep %s to version %s.\n" "${target_dependency}" "${target_version}"
  mv ${git_root}/Mercator.swift/Package.swift.bak ${git_root}/Mercator.swift/Package.swift
  exit 1
fi
