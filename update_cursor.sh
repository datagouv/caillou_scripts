#!/bin/bash

# Script to download and install the latest version of Cursor for Linux
# This script fetches the download page, finds the Linux .deb (x64) link,
# downloads the package, and installs it using dpkg

set -e  # Exit on error

echo "🔍 Fetching Cursor download page..."

# Download the page and extract the Linux .deb (x64) download link
# The page contains JSON data with downloadUrl and label fields
# We look for any URL containing "linux-x64-deb" to be flexible with URL structure changes
DOWNLOAD_URL=$(curl -s https://cursor.com/download | grep -o 'https://[^"]*linux-x64-deb[^"]*' | head -1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ Error: Could not find the Linux .deb download link"
    exit 1
fi

echo "✅ Found download link: $DOWNLOAD_URL"

echo "📥 Downloading Cursor..."
# Get the final redirect URL which contains the actual filename
FINAL_URL=$(curl -sIL "$DOWNLOAD_URL" | grep -i "^location:" | tail -1 | sed 's/location: //i' | tr -d '\r')

# Extract filename from the final URL
if [ -n "$FINAL_URL" ]; then
    ACTUAL_FILENAME=$(basename "$FINAL_URL")
    TEMP_FILE="$HOME/Downloads/$ACTUAL_FILENAME"
else
    # Fallback if no redirect found
    ACTUAL_FILENAME=$(basename "$DOWNLOAD_URL")
    TEMP_FILE="$HOME/Downloads/$ACTUAL_FILENAME"
fi

echo "📦 Downloading: $ACTUAL_FILENAME"
curl -L --http1.1 -o "$TEMP_FILE" "$DOWNLOAD_URL"

if [ -z "$TEMP_FILE" ] || [ ! -f "$TEMP_FILE" ]; then
    echo "❌ Error: Download failed or .deb file not found"
    exit 1
fi

echo "✅ Download complete: $TEMP_FILE"

# Install the package
echo "📦 Installing Cursor..."
sudo dpkg -i "$TEMP_FILE"

# Fix any dependency issues
echo "🔧 Fixing dependencies if needed..."
sudo apt-get install -f -y

echo "✅ Cursor has been successfully updated!"

