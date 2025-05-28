#!/bin/bash

SCREENSHOT_DIR="/Users/ewern/code/localOCRtoClipboard/screenshots"
mkdir -p "$SCREENSHOT_DIR"

echo "Watching for screenshots..."
echo "Use Cmd+Shift+4 to take screenshots - they'll be OCR'd automatically"

/opt/homebrew/bin/fswatch -0 "$SCREENSHOT_DIR" | while read -d "" path; do
    if [[ "$path" == *.png || "$path" == *.jpg || "$path" == *.JPG || "$path" == *.PNG ]] && [ -f "$path" ]; then
        # Run OCR and copy to clipboard
        /opt/homebrew/bin/tesseract "$path" stdout -l eng 2>/dev/null | pbcopy
        
        # Delete the screenshot
        rm "$path"
        
        # Notification
        osascript -e 'display notification "Text copied to clipboard" with title "OCR Complete"'
    fi
done