#!/bin/bash

echo "🚀 Setting up Local OCR to Clipboard..."

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install from https://brew.sh"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
brew list tesseract &>/dev/null || brew install tesseract
brew list fswatch &>/dev/null || brew install fswatch

# Create screenshots directory
echo "📁 Creating screenshots directory..."
mkdir -p "$DIR/screenshots"

# Update paths in watch-ocr.sh
echo "🔧 Configuring scripts..."
sed -i '' "s|/Users/ewern/code/localOCRtoClipboard|$DIR|g" "$DIR/watch-ocr.sh"

# Update paths in plist
sed -i '' "s|/Users/ewern/code/localOCRtoClipboard|$DIR|g" "$DIR/com.local.ocr-watcher.plist"

# Make script executable
chmod +x "$DIR/watch-ocr.sh"

# Copy and load launch agent
echo "🚀 Installing background service..."
cp "$DIR/com.local.ocr-watcher.plist" ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.local.ocr-watcher.plist

# Set screenshot location
echo "📸 Setting screenshot save location..."
defaults write com.apple.screencapture location "$DIR/screenshots"

# Disable screenshot thumbnail
defaults write com.apple.screencapture show-thumbnail -bool false

echo "✅ Setup complete!"
echo ""
echo "How to use:"
echo "1. Press Cmd+Shift+4 to take a screenshot"
echo "2. Select area with text"
echo "3. Text is automatically copied to clipboard!"
echo ""
echo "Screenshot location: $DIR/screenshots"