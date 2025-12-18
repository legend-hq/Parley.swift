#!/bin/bash

set -euo pipefail

git_root=$(git rev-parse --show-toplevel)

prefix=${1:-}
dep_name=${2:-}
target_version=${3:-}

function print_usage() {
  >&2 printf 'Usage: %s <subtree_prefix> <dependency_name> <new_version_tag>\n' "${self%%$(pwd)/}"
  >&2 printf 'Example: %s atlas.ex atlas\n' "${self%%$(pwd)/}"
}

if [[ -z "${target_version}" ]]; then
  >&2 printf "‼ Missing version\n"
  print_usage
  exit 1
fi

if [[ -z "${prefix}" ]]; then
  >&2 printf "‼ Missing subtree prefix\n"
  print_usage
  exit 1
fi

if [[ -z "${dep_name}" ]]; then
  >&2 printf "‼ Missing dependency name\n"
  print_usage
  exit 1
fi

resolved_hash=$(cd ${git_root} && git subtree split --prefix ${prefix})

cd ${git_root}/Mercator.swift

jq ".pins |= map(
        if .identity == \"${dep_name}\" then
            .state.revision = \"${resolved_hash}\"
            | .state.version = \"${target_version}\"
        else
            .
        end
    )" Package.resolved > Package.resolved.new

# Package.lock json is formatted with spaces between key and colon. idk.
sed -i.bak -Ee 's/":/" :/g' Package.resolved.new
rm Package.resolved.new.bak

prelen=$(wc -l Package.resolved | cut -d ' ' -f 1)
newlen=$(wc -l Package.resolved.new | cut -d ' ' -f 1)

if [[ "${newlen}" -ge "${prelen}" ]]; then
  mv Package.resolved.new Package.resolved
  printf '✓ Updated lock for %s to %s @ %s\n' "${dep_name}" "${target_version}" "${resolved_hash}"
else
  rm Package.resolved.new
  >&2 printf '✗ Failed to update lock for %s to %s @ %s\n' "${dep_name}" "${target_version}" "${resolved_hash}"
  exit 1
fi
