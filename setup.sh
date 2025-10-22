#!/bin/bash
set -e

# Default values
UNINSTALL=false
SCREENSHOT_DIR="/tmp/ocr-screenshots"

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--uninstall]"
            exit 1
            ;;
    esac
done

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/ocr-watcher"
PLIST_SOURCE="$SCRIPT_DIR/com.local.ocr-watcher.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.local.ocr-watcher.plist"

# Handle uninstall
if [ "$UNINSTALL" = true ]; then
    echo "Uninstalling Local OCR to Clipboard..."

    # Unload launch agent
    launchctl unload "$PLIST_DEST" 2>/dev/null || true

    # Remove plist
    rm -f "$PLIST_DEST"

    # Remove binary
    rm -f "$BINARY_PATH"

    # Reset screenshot settings to macOS defaults
    defaults delete com.apple.screencapture location 2>/dev/null || true
    defaults delete com.apple.screencapture show-thumbnail 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true

    echo "Uninstall complete!"
    echo "Screenshot settings have been reset to macOS defaults."
    exit 0
fi

echo "Setting up Local OCR to Clipboard..."

# Check for Xcode Command Line Tools
if ! command -v swiftc &> /dev/null; then
    echo "Error: Swift compiler not found."
    echo "Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Compile the Swift binary
echo "Compiling OCR watcher..."
"$SCRIPT_DIR/compile.sh"

# Create screenshot directory
mkdir -p "$SCREENSHOT_DIR"

# Update plist with actual binary path
echo "Configuring launch agent..."
sed "s|BINARY_PATH_PLACEHOLDER|$BINARY_PATH|g" "$PLIST_SOURCE" > "$PLIST_DEST"

# Unload if already loaded
launchctl unload "$PLIST_DEST" 2>/dev/null || true

# Load launch agent
echo "Loading launch agent..."
launchctl load "$PLIST_DEST"

# Set screenshot location and disable preview
echo "Configuring screenshot settings..."
defaults write com.apple.screencapture location "$SCREENSHOT_DIR"
defaults write com.apple.screencapture show-thumbnail -bool false
killall SystemUIServer 2>/dev/null || true

echo ""
echo "Setup complete!"
echo ""
echo "How to use:"
echo "  Press Cmd+Shift+4 (native macOS screenshot hotkey)"
echo "  Select area with text"
echo "  Text is automatically OCR'd and copied to clipboard"
echo ""
echo "Screenshots saved to: $SCREENSHOT_DIR (auto-cleaned on reboot)"
echo ""
echo "Logs available at:"
echo "  /tmp/ocr-watcher.log"
echo "  /tmp/ocr-watcher-error.log"
