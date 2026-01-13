#!/bin/bash
# Setup script for CAR-bench scenario
# This downloads the car-bench code and large data files required to run the benchmark

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAR_BENCH_DIR="$SCRIPT_DIR/car-bench"
DATA_VERSION="v1.0.0"  # Update this to match your release version

if [ -d "$CAR_BENCH_DIR" ]; then
    echo "car-bench already exists at $CAR_BENCH_DIR"
    echo "To re-download, remove the directory first: rm -rf $CAR_BENCH_DIR"
    exit 0
fi

echo "Cloning car-bench repository..."
git clone --depth 1 https://github.com/CAR-bench/car-bench.git "$CAR_BENCH_DIR"

echo "Downloading large mock_data files from GitHub release..."

# Check if zip exists in parent directory (before we cd)
if [ -f "$SCRIPT_DIR/navigation_mock_data.zip" ] && [ $(wc -c < "$SCRIPT_DIR/navigation_mock_data.zip") -gt 1000 ]; then
    echo "✓ Found navigation_mock_data.zip in scenarios/car-bench/, moving it"
    mv "$SCRIPT_DIR/navigation_mock_data.zip" "$CAR_BENCH_DIR/"
fi

cd "$CAR_BENCH_DIR"

# Check if file already exists (manual download)
if [ -f "navigation_mock_data.zip" ] && [ $(wc -c < navigation_mock_data.zip) -gt 1000 ]; then
    echo "✓ Found existing navigation_mock_data.zip, skipping download"
else
    # GitHub release asset download URL
    DOWNLOAD_URL="https://github.com/CAR-bench/car-bench/releases/download/${DATA_VERSION}/navigation_mock_data.zip"

    echo "Attempting to download from GitHub release..."
    
    # Check if GITHUB_TOKEN is set (for private repos)
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "Using GITHUB_TOKEN for authentication"
        if command -v curl &> /dev/null; then
            curl -L -H "Authorization: token $GITHUB_TOKEN" \
                 -H "Accept: application/octet-stream" \
                 "$DOWNLOAD_URL" -o navigation_mock_data.zip
        else
            wget --header="Authorization: token $GITHUB_TOKEN" \
                 --header="Accept: application/octet-stream" \
                 "$DOWNLOAD_URL" -O navigation_mock_data.zip
        fi
    else
        # Try without authentication (for public repos)
        if command -v wget &> /dev/null; then
            wget --content-disposition "$DOWNLOAD_URL" -O navigation_mock_data.zip
        elif command -v curl &> /dev/null; then
            curl -L "$DOWNLOAD_URL" -o navigation_mock_data.zip
        else
            echo "Error: Neither wget nor curl is available"
            exit 1
        fi
    fi

    # Verify the download
    if [ ! -s navigation_mock_data.zip ] || [ $(wc -c < navigation_mock_data.zip) -lt 1000 ]; then
        echo ""
        echo "❌ Error: Failed to download navigation_mock_data.zip"
        echo ""
        if [ -z "$GITHUB_TOKEN" ]; then
            echo "⚠️  The CAR-bench repository appears to be private."
            echo ""
            echo "Option 1: Set GITHUB_TOKEN environment variable"
            echo "  export GITHUB_TOKEN=your_github_token"
            echo "  ./scenarios/car-bench/setup.sh"
            echo ""
            echo "Option 2: Download manually"
        else
            echo "Please download manually:"
        fi
        echo "  1. Visit: https://github.com/CAR-bench/car-bench/releases/tag/${DATA_VERSION}"
        echo "  2. Download: navigation_mock_data.zip (47.9 MB)"
        echo "  3. Move it to: $CAR_BENCH_DIR/navigation_mock_data.zip"
        echo "  4. Run this script again"
        echo ""
        rm -f navigation_mock_data.zip
        exit 1
    fi
    
    echo "✓ Download successful ($(du -h navigation_mock_data.zip | cut -f1))"
fi

echo "Extracting large data files into mock_data directory..."
unzip -o navigation_mock_data.zip -d car_bench/envs/car_voice_assistant/mock_data/navigation/
rm navigation_mock_data.zip

echo ""
echo "✅ Setup complete! car-bench is ready at:"
echo "   $CAR_BENCH_DIR"
echo ""
echo "📦 Mock data location:"
echo "   $CAR_BENCH_DIR/car_bench/envs/car_voice_assistant/mock_data"
echo ""
echo "🚀 To run the CAR-bench scenario:"
echo "   uv run agentbeats-run scenarios/car-bench/scenario.toml"
echo ""
echo "💡 To use a different data directory, set CAR_BENCH_DATA_DIR:"
echo "   CAR_BENCH_DATA_DIR=/path/to/data uv run agentbeats-run scenarios/car-bench/scenario.toml"
