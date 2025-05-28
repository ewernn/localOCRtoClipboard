# Local OCR to Clipboard (macOS)

Automatically OCR screenshots and copy text to clipboard on macOS. No cloud services, runs 100% locally.

MacOS OCR is grudgingly slow...

## Quick Setup

```bash
git clone https://github.com/ewernn/localOCRtoClipboard.git
cd localOCRtoClipboard
./setup.sh
```

That's it! 🎉 Screenshots will be saved to `localOCRtoClipboard/screenshots/`

## Example

![Example](example.mp4)

## Usage

1. Press **Cmd+Shift+4**
2. Select text in any app
3. Text is instantly in your clipboard!

## How it works

- Uses macOS native screenshot tool
- Tesseract OCR extracts text locally
- Auto-deletes screenshots after processing
- Runs silently in background

## Uninstall

```bash
./uninstall.sh
```

## Manual Setup

If you prefer to set up manually:

1. Install dependencies:
   ```bash
   brew install tesseract fswatch
   ```

2. Update paths in `watch-ocr.sh` and `com.local.ocr-watcher.plist`

3. Install launch agent:
   ```bash
   cp com.local.ocr-watcher.plist ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/com.local.ocr-watcher.plist
   ```

4. Set screenshot location:
   ```bash
   defaults write com.apple.screencapture location /path/to/screenshots
   ```

## Requirements

- macOS
- Homebrew