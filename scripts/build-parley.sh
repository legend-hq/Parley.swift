#!/bin/bash

set -euo pipefail

swiftly=$(command -v swiftly || command -v "${HOME}/.swiftly/bin/swiftly")

# Default to debug mode
CONFIG="debug"
COPY_DEST=""
OPTIMIZE=false
WASM_OPT=${WASM_OPT:-"wasm-opt"}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            CONFIG="debug"
            shift
            ;;
        --release)
            CONFIG="release"
            shift
            ;;
        --optimize)
            OPTIMIZE=true
            shift
            ;;
        --copy)
            if [ -z "$2" ]; then
                echo "Error: --copy requires a destination directory argument"
                exit 1
            fi
            COPY_DEST="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--debug|--release] [--optimize] [--copy <destination>]"
            echo "  --debug   - Build with debug symbols and no optimizations (default)"
            echo "  --release - Build with optimizations and without debug symbols"
            echo "  --optimize - Further optimize WASM output using wasm-opt"
            echo "  --copy <destination> - Copy built WASM to <destination>/apps/mercator/priv/parley/1.0.0/"
            echo ""
            echo "Example: $0 --release --optimize --copy ../legend"
            exit 1
            ;;
    esac
done

# If copy destination is specified, verify it exists
if [ -n "$COPY_DEST" ]; then
    if [ ! -d "$COPY_DEST" ]; then
        echo "Error: Destination directory '$COPY_DEST' does not exist"
        exit 1
    fi

    # Check if the target directory structure exists or can be created
    TARGET_DIR="$COPY_DEST/apps/mercator/priv/parley/1.0.0"
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Creating target directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create target directory"
            exit 1
        fi
    fi
fi

echo "Building Parley in $CONFIG mode..."

# Check for required swift sdk and provide instructions if missing
sdk_base_url="https://download.swift.org/swift-6.2-branch/wasm-sdk"
target_base_sdk="swift-6.2-DEVELOPMENT-SNAPSHOT-2025-09-27-a"
target_wasm_sdk="${target_base_sdk}_wasm"
wasm_sdk_url="${sdk_base_url}/${target_base_sdk}/${target_wasm_sdk}.artifactbundle.tar.gz"
wasm_sdk_checksum="2535f53de0ada00a74bd097d36d94f6b41670b34a877c236850ee28194cb36d2"

if ! grep -q "${target_wasm_sdk}" <(${swiftly} run swift sdk list); then
    echo "Error: Swift SDK ${target_wasm_sdk} not found"
    echo "Try running \`${swiftly} run swift sdk install ${wasm_sdk_url} --checksum ${wasm_sdk_checksum}\`"
    exit 1
fi

# Base build command
BUILD_CMD="${swiftly} run swift build --swift-sdk ${target_wasm_sdk} --product Parley --configuration $CONFIG"

# Add aggressive optimizations for release builds
if [ "$CONFIG" = "release" ]; then
    echo "Applying aggressive optimizations for smaller/faster WASM output..."
    BUILD_CMD="$BUILD_CMD \
        -Xswiftc -O \
        -Xswiftc -whole-module-optimization \
        -Xswiftc -cross-module-optimization \
        -Xswiftc -Osize \
        -Xswiftc -enable-bare-slash-regex \
        -Xswiftc -remove-runtime-asserts \
        -Xswiftc -assume-single-threaded \
        -Xswiftc -enforce-exclusivity=unchecked \
        -Xcc -Os \
        -Xcc -flto \
        -Xlinker --strip-all \
        -Xlinker --gc-sections \
        -Xlinker -O3"

    echo "Note: Release build will be significantly slower but produce optimized WASM"
fi

# Execute the build
cd $(dirname ${0})/..
eval $BUILD_CMD

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build completed successfully"

    SOURCE_FILE=".build/$CONFIG/Parley.wasm"

    # Run wasm-opt if --optimize flag is set
    if [ "$OPTIMIZE" = true ]; then
        OPTIMIZED_FILE=".build/$CONFIG/Parley-optimized.wasm"

        # Check if wasm-opt is available
        if ! command -v ${WASM_OPT} &> /dev/null; then
            echo "Warning: wasm-opt not found in PATH. Skipping optimization."
            echo "Install with: npm install -g wasm-opt or brew install binaryen"
        else
            echo "Running wasm-opt to further optimize WASM output..."
            ${WASM_OPT} -Oz --enable-bulk-memory "$SOURCE_FILE" -o "$OPTIMIZED_FILE"

            if [ $? -eq 0 ]; then
                echo "Optimization completed successfully"
                # Update source file to use the optimized version for copying
                SOURCE_FILE="$OPTIMIZED_FILE"
            else
                echo "Warning: wasm-opt failed. Using non-optimized WASM."
            fi
        fi
    fi

    # Copy the WASM file if requested
    if [ -n "$COPY_DEST" ]; then
        TARGET_FILE="$COPY_DEST/apps/mercator/priv/parley/1.0.0/Parley.wasm"

        if [ -f "$SOURCE_FILE" ]; then
            echo "Copying $SOURCE_FILE to $TARGET_FILE"
            cp "$SOURCE_FILE" "$TARGET_FILE"
            if [ $? -eq 0 ]; then
                echo "Copy completed successfully"
            else
                echo "Error: Failed to copy WASM file"
                exit 1
            fi
        else
            echo "Error: Built WASM file not found at $SOURCE_FILE"
            exit 1
        fi
    fi
else
    echo "Build failed"
    exit 1
fi
