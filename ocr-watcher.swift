import Foundation
import Vision
import AppKit

class OCRWatcher {
    let watchPath: String
    var eventStream: FSEventStreamRef?

    init(watchPath: String) {
        self.watchPath = watchPath

        // Create watch directory if it doesn't exist
        try? FileManager.default.createDirectory(atPath: watchPath, withIntermediateDirectories: true)
    }

    func startWatching() {
        // Set stdout/stderr to be unbuffered
        setbuf(stdout, nil)
        setbuf(stderr, nil)

        print("[\(Date())] OCR Watcher starting...")
        print("[\(Date())] Watching directory: \(watchPath)")

        // Check for existing files first
        checkDirectory(watchPath)

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds in
            let watcher = Unmanaged<OCRWatcher>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()

            print("[\(Date())] FSEvent detected, numEvents: \(numEvents)")

            let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]

            for (index, path) in paths.enumerated() {
                let flags = eventFlags[index]
                print("[\(Date())] Event for path: \(path), flags: \(flags)")
                watcher.checkDirectory(path)
            }
        }

        let pathsToWatch = [watchPath] as CFArray

        eventStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5, // latency in seconds
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents)
        )

        guard let stream = eventStream else {
            print("[\(Date())] ERROR: Failed to create FSEventStream")
            return
        }

        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        if FSEventStreamStart(stream) {
            print("[\(Date())] FSEventStream started successfully")
        } else {
            print("[\(Date())] ERROR: Failed to start FSEventStream")
        }

        print("[\(Date())] Ready! Press Cmd+Shift+4 to take a screenshot")

        // Keep the run loop running
        RunLoop.current.run()
    }

    func checkDirectory(_ path: String) {
        print("[\(Date())] Checking directory: \(path)")

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: watchPath)
            print("[\(Date())] Found \(contents.count) files")

            for file in contents {
                let fullPath = (watchPath as NSString).appendingPathComponent(file)
                let fileExtension = (file as NSString).pathExtension.lowercased()

                print("[\(Date())] File: \(file), extension: \(fileExtension)")

                if ["png", "jpg", "jpeg"].contains(fileExtension) {
                    print("[\(Date())] Processing image: \(file)")
                    // Small delay to ensure file is fully written
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.processImage(at: fullPath)
                    }
                }
            }
        } catch {
            print("[\(Date())] ERROR reading directory: \(error)")
        }
    }

    func processImage(at path: String) {
        print("[\(Date())] processImage called for: \(path)")

        guard FileManager.default.fileExists(atPath: path) else {
            print("[\(Date())] File no longer exists: \(path)")
            return
        }

        print("[\(Date())] Loading image...")
        guard let image = NSImage(contentsOfFile: path) else {
            print("[\(Date())] ERROR: Failed to load image: \(path)")
            return
        }

        print("[\(Date())] Converting to CGImage...")
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("[\(Date())] ERROR: Failed to get CGImage")
            return
        }

        print("[\(Date())] Starting OCR...")

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR error: \(error)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            if !recognizedText.isEmpty {
                self.copyToClipboard(recognizedText)
                self.showNotification()
            }

            // Delete the screenshot
            try? FileManager.default.removeItem(atPath: path)
        }

        // Configure for fast, accurate text recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform OCR: \(error)")
            }
        }
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("Text copied to clipboard (\(text.count) characters)")
    }

    func showNotification() {
        // Use NSUserNotificationCenter for command-line tools (deprecated but works)
        // Or use osascript as a fallback
        let script = """
        display notification "Text copied to clipboard" with title "OCR Complete"
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        do {
            try task.run()
        } catch {
            print("Failed to show notification: \(error)")
        }
    }

    deinit {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}

// Main entry point
let watchPath = "/tmp/ocr-screenshots"
let watcher = OCRWatcher(watchPath: watchPath)
watcher.startWatching()
