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

if ! (cd ${git_root}/Parley.swift && ${swiftly} run swift build --build-tests --force-resolved-versions); then
  >&2 printf "‼ Parley.swift failed to build. Do not release broken code.\n"
  exit 1
fi

if ! (cd ${git_root}/Parley.swift && retry_upto 30 "${swiftly} run swift test --force-resolved-versions"); then
  >&2 printf "‼ Parley.swift has failing tests. Do not release broken code.\n"
  exit 1
fi

printf '──────────────────────────────────────────────────────────────────\n'
printf '(Parley.swift) Preconditions satisfied. Preparing release...\n'
printf '──────────────────────────────────────────────────────────────────\n'

# update Charter.swift version to the release version under preparation
${git_root}/Parley.swift/scripts/set-version.sh "${target_version}"

printf '(Parley.swift) Compiling optimized Parley.wasm...\n'
printf '──────────────────────────────────────────────────────────────────\n'

printf '» Compiling a release-optimized Parley.wasm...\n'
# compile an updated Parley.wasm binary
WASM_OPT=${git_root}/wasm-opt.sh \
  ${git_root}/Parley.swift/scripts/build-parley.sh --release

# NOTE: Atlas.swift is a path dependency in the monorepo, so no version update needed.
# The local path dependency will automatically use the Atlas.swift code in this repo.

# if there are no changes, there is nothing to stage; abort
if [[ ${UNCHANGED:-} != ok ]] && [[ -z $(git status --porcelain ${git_root}/Parley.swift) ]]; then
  >&2 printf "‼ Release is pointless.\n"
  >&2 printf "    %s\n" "Parley.swift is already up-to-date."
  exit 1
fi

printf "✓ Prepared Parley.swift ${target_version} for release.\n"
