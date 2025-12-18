#!/bin/bash
set -euo pipefail

git_root=$(git rev-parse --show-toplevel)

target_version=${1:-}

swiftly=$(command -v swiftly || command -v "${HOME}/.swiftly/bin/swiftly")

# load retry-upto shared helper function
source ${git_root}/retry-upto.sh

if [[ -z "${target_version}" ]]; then
  >&2 printf "‼ Missing version\n"
  >&2 printf "Usage: prepare-release.sh <version>\n"
  exit 1
fi

if [[ $(${git_root}/semver.sh validate "${target_version}") == invalid ]]; then
  >&2 printf "‼ Invalid version: %s\n" "${target_version}"
  exit 1
fi

if [[ -n $(git status --porcelain ${git_root}/Mercator.swift) ]]; then
  >&2 printf "‼ Working tree is dirty. Stash or commit your changes.\n"
  exit 1
fi

if ! (cd ${git_root}/Mercator.swift && ${swiftly} run swift build --build-tests --force-resolved-versions); then
  >&2 printf "‼ Mercator.swift failed to build. Do not release broken code.\n"
  exit 1
fi

if ! (cd ${git_root}/Mercator.swift && retry_upto 30 "${swiftly} run swift test --force-resolved-versions"); then
  >&2 printf "‼ Mercator.swift has failing tests. Do not release broken code.\n"
  exit 1
fi

printf '──────────────────────────────────────────────────────────────────\n'
printf '(Mercator.swift) Preconditions satisfied. Preparing release...\n'
printf '──────────────────────────────────────────────────────────────────\n'

# update Charter.swift version to the release version under preparation
${git_root}/Mercator.swift/scripts/set-version.sh "${target_version}"

printf '(Mercator.swift) Compiling optimized Parley.wasm...\n'
printf '──────────────────────────────────────────────────────────────────\n'

printf '» Compiling a release-optimized Parley.wasm...\n'
# compile an updated Parley.wasm binary
WASM_OPT=${git_root}/wasm-opt.sh \
  ${git_root}/Mercator.swift/scripts/build-parley.sh --release

printf '(Mercator.swift) Updating Atlas.swift version...\n'
printf '──────────────────────────────────────────────────────────────────\n'

# update Atlas.swift version tag to the release version under preparation
${git_root}/Mercator.swift/scripts/set-dep-version.sh Atlas "${target_version}"

# if there are no changes, there is nothing to stage; abort
if [[ ${UNCHANGED:-} != ok ]] && [[ -z $(git status --porcelain ${git_root}/Mercator.swift) ]]; then
  >&2 printf "‼ Release is pointless.\n"
  >&2 printf "    %s\n" "Mercator.swift is already up-to-date." "Target: ${revision}"
  exit 1
fi

printf "✓ Prepared Mercator.swift ${target_version} for release.\n"
