#!/bin/bash
# Wrapper script to run Geno from Eth.swift dependency

# Find the Eth.swift checkout directory
ETH_SWIFT_DIR=$(find .build/checkouts -name "Eth.swift*" -type d | head -1)

if [ -z "$ETH_SWIFT_DIR" ]; then
    echo "Error: Eth.swift not found. Run 'swift build' first to fetch dependencies."
    exit 1
fi

# Build Geno if needed and run it
swift build --product Geno --package-path "$ETH_SWIFT_DIR" && \
"$ETH_SWIFT_DIR/.build/debug/Geno" "$@"