#!/bin/sh

set -eo pipefail

# Check if the version argument matches the pattern #.#.#
if ! echo "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: Version must match the pattern #.#.# (e.g., 1.2.3)" >&2
  exit 1
fi

VERSION="$1"

# Download the archive from the specified version
gh release download --repo legend-hq/legend-scripts --pattern "artifacts.zip" "$VERSION"

# Ensure the archive is deleted when the script exits
trap 'rm -f artifacts.zip' EXIT

# Unzip the `out/` folder into the releases directory with the version
mkdir -p legend-script-releases
unzip -o artifacts.zip -d "legend-script-releases/$VERSION"

echo "Artifacts for version $VERSION have been extracted to legend-script-releases/$VERSION."
