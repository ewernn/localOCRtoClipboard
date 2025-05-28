#!/bin/bash

echo "🗑️  Uninstalling Local OCR to Clipboard..."

# Unload and remove launch agent
if [ -f ~/Library/LaunchAgents/com.local.ocr-watcher.plist ]; then
    launchctl unload ~/Library/LaunchAgents/com.local.ocr-watcher.plist
    rm ~/Library/LaunchAgents/com.local.ocr-watcher.plist
    echo "✅ Removed background service"
fi

# Reset screenshot location to Desktop
defaults write com.apple.screencapture location ~/Desktop
echo "✅ Reset screenshot location to Desktop"

# Re-enable screenshot thumbnail
defaults write com.apple.screencapture show-thumbnail -bool true
echo "✅ Re-enabled screenshot thumbnail"

echo ""
echo "✅ Uninstall complete!"
echo "Note: Tesseract and fswatch were not removed (use 'brew uninstall' if needed)"