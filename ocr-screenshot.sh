#!/bin/bash

# Create a dedicated directory for screenshots
SCREENSHOT_DIR="/Users/ewern/code/localOCRtoClipboard/screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Clean up any existing screenshots at start
rm -f "$SCREENSHOT_DIR"/*.png

# Use timestamp for unique filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_PATH="$SCREENSHOT_DIR/screenshot_$TIMESTAMP.png"

# Capture screenshot to specific directory
screencapture -i "$SCREENSHOT_PATH"

# Check if screenshot was created (user didn't cancel)
if [ -f "$SCREENSHOT_PATH" ]; then
    # Run OCR and copy to clipboard
    tesseract "$SCREENSHOT_PATH" stdout -l eng 2>/dev/null | pbcopy
    
    # Delete the screenshot after OCR
    rm "$SCREENSHOT_PATH"
    
    # Simple beep sound
    echo -e "\a"
else
    echo "Screenshot cancelled"
fi