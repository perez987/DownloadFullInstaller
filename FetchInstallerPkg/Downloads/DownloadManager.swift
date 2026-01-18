//
//  DownloadManager.swift
//
//  Created by Armin Briegel on 2021-06-14
//  Modified by Emilio P Egido on 2025-09-23
//

import AppKit
import DockProgress
import Foundation

@objc class DownloadManager: NSObject, ObservableObject {
    @Published var downloadURL: URL?
    @Published var localURL: URL?
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var progressString: String = ""
    @Published var isComplete = false
    @Published var filename: String?
    @Published var installerURLFiles: [URL]?
    @Published var errorMessage: String?

    lazy var urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    var downloadTask: URLSessionDownloadTask?
    var byteFormatter = ByteCountFormatter()

    // Resume functionality properties
    private var resumeData: Data?
    private var retryCount = 0
    private var maxRetries = 100
    private var retryTimer: Timer?
    @Published var isRetrying = false
    
    // Security-scoped resource tracking
    private var destinationURL: URL?
    private var isAccessingSecurityScope = false

    static let shared = DownloadManager()

    // Active download count tracking
    // Thread-safe counter for active downloads, designed for future multi-download support
    private static var activeDownloadCount: Int = 0
    private static let downloadCountLock = NSLock()

    /// Returns the current number of active downloads
    /// This function can be used with DockProgress badge style:
    /// DockProgress.style = .badge(color: .blue, badgeValue: { getDownloadCount() })
    static func getDownloadCount() -> Int {
        downloadCountLock.lock()
        defer { downloadCountLock.unlock() }
        return activeDownloadCount
    }

    private static func incrementDownloadCount() {
        downloadCountLock.lock()
        defer { downloadCountLock.unlock() }
        activeDownloadCount += 1
    }

    private static func decrementDownloadCount() {
        downloadCountLock.lock()
        defer { downloadCountLock.unlock() }
        if activeDownloadCount > 0 {
            activeDownloadCount -= 1
        }
    }

    var fileExists: Bool {
        let destination = Prefs.downloadURL
        if filename != nil {
            let file = destination.appendingPathComponent(filename!)
            
            // Start accessing security-scoped resource for file check
            let accessStarted = destination.startAccessingSecurityScopedResource()
            defer {
                if accessStarted {
                    destination.stopAccessingSecurityScopedResource()
                }
            }
            
            return FileManager.default.fileExists(atPath: file.path)
        } else {
            return false
        }
    }

    func download(url: URL?, replacing: Bool = false) throws {
        // Store the URL for potential resume attempts
        downloadURL = url
        isComplete = false
        byteFormatter.countStyle = .file
        
        // Get destination URL and start accessing security-scoped resource for the entire download lifecycle
        let destination = Prefs.downloadURL
        destinationURL = destination
        if !isAccessingSecurityScope {
            isAccessingSecurityScope = destination.startAccessingSecurityScopedResource()
        }

        if replacing {
            let suggestedFilename = filename ?? "InstallerAssistant.pkg"
            let file = destination.appendingPathComponent(suggestedFilename)
            
            try FileManager.default.removeItem(at: file)
            // Clear resume data if replacing file
            resumeData = nil
        }

        // Increment active download count when starting a new download
        DownloadManager.incrementDownloadCount()
        startDownload()
    }

    private func startDownload() {
        guard let url = downloadURL else { return }

        isDownloading = true
        // Only reset retryCount when starting a new download (not during retries)
        if !isRetrying {
            retryCount = 0
        }
        isRetrying = false

        // Set dock progress style to bar
        DispatchQueue.main.async {
            // Classic white progress bar
//            DockProgress.style = .bar
            // Small circle in the lower right corner, download progresses like a slice of pie
//            DockProgress.style = .pie(color: .blue)
            // Badge with the number of active downloads
            DockProgress.style = .badge(color: .blue, badgeValue: { DownloadManager.getDownloadCount() })
        }

        // Try to resume from previous download if resume data exists
        if let resumeData = resumeData {
            downloadTask = urlSession.downloadTask(withResumeData: resumeData)
            print("Resuming download of \(filename ?? "InstallerAssistant.pkg")")
        } else {
            downloadTask = urlSession.downloadTask(with: url)
            progress = 0.0
            DispatchQueue.main.async {
                DockProgress.progress = 0.0
            }
            localURL = nil
            print("Starting download of \(filename ?? "InstallerAssistant.pkg")")
        }

        downloadTask?.resume()
    }

    func cancel() {
        if isDownloading, downloadTask != nil {
            downloadTask?.cancel { [weak self] _ in
                DispatchQueue.main.async {
                    // Don't preserve resume data for manual cancellation
                    self?.resumeData = nil
                }
            }
            isDownloading = false
            isRetrying = false
            localURL = nil
            downloadURL = nil
            progress = 0.0
            DispatchQueue.main.async {
                DockProgress.progress = 0.0
            }
            retryCount = 0
            retryTimer?.invalidate()
            retryTimer = nil
            // Decrement active download count when cancelled
            DownloadManager.decrementDownloadCount()
            // Stop accessing security-scoped resource
            stopAccessingSecurityScope()
        }
        print("Cancelled download of \(filename ?? "InstallerAssistant.pkg")")
    }
    
    private func stopAccessingSecurityScope() {
        if isAccessingSecurityScope, let destination = destinationURL {
            destination.stopAccessingSecurityScopedResource()
            isAccessingSecurityScope = false
        }
    }

    private func retryDownload() {
        guard retryCount < maxRetries else {
            print("Max retry attempts reached. Download failed.")
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.resumeData = nil
                DockProgress.progress = 0.0
            }
            // Decrement active download count when max retries reached
            DownloadManager.decrementDownloadCount()
            // Stop accessing security-scoped resource
            stopAccessingSecurityScope()
            return
        }

        retryCount += 1 // Number of resume attempts made

        //    let retryDelay = pow(2.0, Double(retryCount)) // Exponential backoff: 2, 4, 8... seconds
        let retryDelay: Double = 5 // Retry interval 5 seconds

        print("Connection lost. Retrying download in \(Int(retryDelay))\"... (Attempt \(retryCount)/\(maxRetries))")
        //    print("Trying to resume download of \(filename ?? "InstallerAssistant.pkg")")

        DispatchQueue.main.async {
            self.isRetrying = true
        }

        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.startDownload()
            }
        }
    }

    func revealInFinder() {
        if isComplete {
            let destination = Prefs.downloadPath
            NSWorkspace.shared.selectFile(localURL?.path, inFileViewerRootedAtPath: destination)
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Use the stored destination URL that already has security-scoped access
        guard let destination = destinationURL else {
            print("Error: No destination URL available")
            DownloadManager.decrementDownloadCount()
            stopAccessingSecurityScope()
            return
        }

        // get the suggest file name or create a uuid string
        let suggestedFilename = filename ?? downloadTask.response?.suggestedFilename ?? UUID().uuidString

        do {
            let file = destination.appendingPathComponent(suggestedFilename)
            let fileExists = FileManager.default.fileExists(atPath: file.path)
            
            let newURL: URL?
            if fileExists {
                // Remove existing file first
                try FileManager.default.removeItem(at: file)
            }
            
            // Copy the file from temp location to destination
            // Using copy instead of move to avoid cross-volume issues and sandbox permissions
            try FileManager.default.copyItem(at: location, to: file)
            newURL = file
            
            // Clean up the temporary file
            do {
                try FileManager.default.removeItem(at: location)
            } catch {
                // Non-critical: temp files will be cleaned by OS eventually
                print("Note: Could not remove temporary file at \(location.path): \(error.localizedDescription)")
            }
            
            print("Finished download of \(filename ?? "InstallerAssistant.pkg")")
            
            // Decrement active download count on successful completion
            DownloadManager.decrementDownloadCount()
            // Stop accessing security-scoped resource after successful save
            stopAccessingSecurityScope()
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.localURL = newURL
                self.isComplete = true
                self.resumeData = nil // Clear resume data on successful completion
                self.retryCount = 0
                self.retryTimer?.invalidate()
                self.retryTimer = nil
                self.errorMessage = nil
                DockProgress.progress = 0.0
            }
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            
            // Decrement download count on failure too
            DownloadManager.decrementDownloadCount()
            // Stop accessing security-scoped resource on failure
            stopAccessingSecurityScope()
            
            // Extract folder name from destination path for error message
            let folderName = destination.lastPathComponent
            let errorMsg = String(format: NSLocalizedString("The file '%@' could not be saved to the '%@' folder. Error: %@", comment: "Download save error"), suggestedFilename, folderName, error.localizedDescription)
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.isComplete = false
                self.errorMessage = errorMsg
                self.resumeData = nil
                self.retryCount = 0
                self.retryTimer?.invalidate()
                self.retryTimer = nil
                DockProgress.progress = 0.0
            }
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progressString = "\(self.byteFormatter.string(fromByteCount: totalBytesWritten))/\(self.byteFormatter.string(fromByteCount: totalBytesExpectedToWrite))"
            DockProgress.progress = self.progress
        }
    }

    // Handle download resumption
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("Download resumed at offset: \(fileOffset) bytes")
        DispatchQueue.main.async {
            self.progress = Double(fileOffset) / Double(expectedTotalBytes)
            self.progressString = "\(self.byteFormatter.string(fromByteCount: fileOffset))/\(self.byteFormatter.string(fromByteCount: expectedTotalBytes))"
            DockProgress.progress = self.progress
        }
    }
}

// MARK: - URLSessionTaskDelegate methods for error handling

extension DownloadManager: URLSessionTaskDelegate {
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }

        print("Download error: \(error.localizedDescription)")
        //		print("Download error occurred: the Internet connection has been lost")

        // Check if this is a network error that we can recover from
        let nsError = error as NSError
        let isNetworkError = nsError.domain == NSURLErrorDomain &&
            (nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotConnectToHost)

        if isNetworkError {
            // Try to get resume data if available
            if let resumeDataFromError = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                resumeData = resumeDataFromError
                print("Resume data saved for future retry")
            }

            // Attempt to retry the download
            DispatchQueue.main.async {
                self.retryDownload()
            }
        } else {
            // Non-recoverable error
            print("Non-recoverable error: \(error.localizedDescription)")
            // Decrement active download count on non-recoverable error
            DownloadManager.decrementDownloadCount()
            // Stop accessing security-scoped resource on non-recoverable error
            stopAccessingSecurityScope()
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.resumeData = nil
                self.retryCount = 0
                self.retryTimer?.invalidate()
                self.retryTimer = nil
                DockProgress.progress = 0.0
            }
        }
    }
}
