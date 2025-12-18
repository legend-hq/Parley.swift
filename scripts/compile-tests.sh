#!/bin/bash

set -euo pipefail

echo "Compiling tests..."
swift build --build-tests "$@"
