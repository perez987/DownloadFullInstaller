//
//  MultiDownloadManager.swift
//
// Created by Emilio P Egido on 2025-12-01
// Manages multiple simultaneous downloads (up to 3)
//

import AppKit

// import DockProgress
import Foundation

// MARK: - DownloadItem

/// Represents a single download instance with its own progress tracking
class DownloadItem: NSObject, ObservableObject, Identifiable, @unchecked Sendable {
    let id = UUID()

    @Published var downloadURL: URL?
    @Published var localURL: URL?
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var progressString: String = ""
    @Published var isComplete = false
    @Published var filename: String?
    @Published var isRetrying = false
    @Published var errorMessage: String?

    private var resumeData: Data?
    private var retryCount = 0
    private var maxRetries = 100
    private var retryTimer: Timer?
    private var lastProgressUpdate: Date = .distantPast

    // Security-scoped resource tracking
    private var destinationURL: URL?
    private var isAccessingSecurityScope = false

    lazy var urlSession = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
    var downloadTask: URLSessionDownloadTask?
    var byteFormatter = ByteCountFormatter()

    /// Reference to parent manager for notifications
    weak var manager: MultiDownloadManager?

    var fileExists: Bool {
        let destination = Prefs.downloadURL
        if filename != nil {
            let file = destination.appendingPathComponent(filename!)

            // Start accessing security-scoped resource for file check (only if needed)
            let accessStarted = Prefs.startAccessingDownloadURL()
            defer {
                Prefs.stopAccessingDownloadURL(accessStarted)
            }

            return FileManager.default.fileExists(atPath: file.path)
        } else {
            return false
        }
    }

    func download(url: URL?, replacing: Bool = false) throws {
        downloadURL = url
        isComplete = false
        byteFormatter.countStyle = .file

        // Get destination URL and start accessing security-scoped resource for the entire download lifecycle (only if needed)
        let destination = Prefs.downloadURL
        destinationURL = destination
        if !isAccessingSecurityScope {
            isAccessingSecurityScope = Prefs.startAccessingDownloadURL()
        }

        if replacing {
            let suggestedFilename = filename ?? "InstallerAssistant.pkg"
            let file = destination.appendingPathComponent(suggestedFilename)

            try FileManager.default.removeItem(at: file)
            resumeData = nil
        }

        Task { @MainActor [weak self] in self?.startDownload() }
    }

    @MainActor
    private func startDownload() {
        guard let url = downloadURL else { return }

        isDownloading = true
        if !isRetrying {
            retryCount = 0
        }
        isRetrying = false

        // Update dock progress directly (already on main actor)
        manager?.updateDockProgress()

        if let resumeData {
            downloadTask = urlSession.downloadTask(withResumeData: resumeData)
            print("Resuming download of \(filename ?? "InstallerAssistant.pkg")")
        } else {
            downloadTask = urlSession.downloadTask(with: url)
            progress = 0.0
            localURL = nil
            print("Starting download of \(filename ?? "InstallerAssistant.pkg")")
        }

        downloadTask?.resume()
    }

    @MainActor
    func cancel() {
        if isDownloading, downloadTask != nil {
            downloadTask?.cancel { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.resumeData = nil
                }
            }
            isDownloading = false
            isRetrying = false
            localURL = nil
            downloadURL = nil
            progress = 0.0
            retryCount = 0
            retryTimer?.invalidate()
            retryTimer = nil
            // Stop accessing security-scoped resource
            stopAccessingSecurityScope()
            // Clean up temporary files off the main thread to avoid UI stalls
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.cleanupTempDirectory()
            }
            // Remove from active downloads immediately on the main actor (no Task wrapper needed)
            manager?.downloadCancelled(self)
        }
        print("Cancelled download of \(filename ?? "InstallerAssistant.pkg")")
    }

    private func cleanupTempDirectory() {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey])
            var deletedCount = 0
            var totalSize: Int64 = 0

            for file in tempFiles {
                do {
                    // Only delete regular files (not directories)
                    let resourceValues = try file.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    guard resourceValues.isRegularFile == true else { continue }

                    // Get file size before deletion
                    let fileSize = resourceValues.fileSize ?? 0

                    try FileManager.default.removeItem(at: file)
                    deletedCount += 1
                    totalSize += Int64(fileSize)
                } catch {
                    // Continue with other files if one fails
                    print("Failed to delete temp file \(file.lastPathComponent): \(error.localizedDescription)")
                }
            }

            if deletedCount > 0 {
                let sizeString = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
                print("Cleaned up temporary directory: deleted \(deletedCount) file(s), freed \(sizeString)")
            }
        } catch {
            print("Failed to access temporary directory for cleanup: \(error.localizedDescription)")
        }
    }

    private func stopAccessingSecurityScope() {
        if isAccessingSecurityScope {
            Prefs.stopAccessingDownloadURL(isAccessingSecurityScope)
            isAccessingSecurityScope = false
        }
    }

    private func retryDownload() {
        guard retryCount < maxRetries else {
            print("Max retry attempts reached. Download failed.")
            Task { @MainActor [weak self] in
                guard let self else { return }
                isDownloading = false
                isRetrying = false
                resumeData = nil
                stopAccessingSecurityScope()
                manager?.downloadFailed(self)
            }
            return
        }

        retryCount += 1
        let retryDelay: Double = 5

        print("Connection lost. Retrying download in \(Int(retryDelay))\"... (Attempt \(retryCount)/\(maxRetries))")

        Task { @MainActor [weak self] in
            self?.isRetrying = true
        }

        retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.startDownload()
            }
        }
    }

    func revealInFinder() {
        if isComplete {
            let destination = Prefs.downloadURL.path
            NSWorkspace.shared.selectFile(localURL?.path, inFileViewerRootedAtPath: destination)
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadItem: URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Use the stored destination URL that already has security-scoped access
        guard let destination = destinationURL else {
            print("Error: No destination URL available")
            stopAccessingSecurityScope()
            return
        }

        let suggestedFilename = filename ?? downloadTask.response?.suggestedFilename ?? UUID().uuidString

        do {
            let file = destination.appendingPathComponent(suggestedFilename)
            let fileExists = FileManager.default.fileExists(atPath: file.path)

            let newURL: URL?
            if fileExists {
                // Remove existing file first
                try FileManager.default.removeItem(at: file)
            }

            // Move the file from temp location to destination
            // Using moveItem to avoid requiring double disk space
            // moveItem handles cross-volume moves internally
            try FileManager.default.moveItem(at: location, to: file)
            newURL = file

            print("Finished download of \(filename ?? "InstallerAssistant.pkg")")

            // Stop accessing security-scoped resource after successful save
            stopAccessingSecurityScope()

            Task { @MainActor [weak self] in
                guard let self else { return }
                isDownloading = false
                isRetrying = false
                localURL = newURL
                isComplete = true
                resumeData = nil
                retryCount = 0
                retryTimer?.invalidate()
                retryTimer = nil
                errorMessage = nil
                manager?.downloadCompleted(self)
            }
        } catch {
            print("Error saving file: \(error.localizedDescription)")

            // Stop accessing security-scoped resource on failure
            stopAccessingSecurityScope()

            // Extract folder name from destination path for error message
            let folderName = destination.lastPathComponent
            let errorMsg = String(format: NSLocalizedString("The file '%@' could not be saved to the '%@' folder. Error: %@", comment: "Download save error"), suggestedFilename, folderName, error.localizedDescription)

            Task { @MainActor [weak self] in
                guard let self else { return }
                isDownloading = false
                isRetrying = false
                isComplete = false
                errorMessage = errorMsg
                resumeData = nil
                retryCount = 0
                retryTimer?.invalidate()
                retryTimer = nil
                manager?.downloadFailed(self)
            }
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Throttle UI updates to at most 20 per second to avoid flooding the main actor queue
        let now = Date()
        guard now.timeIntervalSince(lastProgressUpdate) >= 0.05 else { return }
        lastProgressUpdate = now
        let prog = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let str = "\(byteFormatter.string(fromByteCount: totalBytesWritten))/\(byteFormatter.string(fromByteCount: totalBytesExpectedToWrite))"
        DispatchQueue.main.async { [weak self] in
            self?.progress = prog
            self?.progressString = str
            self?.manager?.updateDockProgress()
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("Download resumed at offset: \(fileOffset) bytes")
        let prog = Double(fileOffset) / Double(expectedTotalBytes)
        let str = "\(byteFormatter.string(fromByteCount: fileOffset))/\(byteFormatter.string(fromByteCount: expectedTotalBytes))"
        DispatchQueue.main.async { [weak self] in
            self?.progress = prog
            self?.progressString = str
            self?.manager?.updateDockProgress()
        }
    }
}

// MARK: - URLSessionTaskDelegate

extension DownloadItem: URLSessionTaskDelegate {
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }

        // Ignore cancellation errors — these are expected when the user cancels a download
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return
        }

        print("Download error: \(error.localizedDescription)")
        let isNetworkError = nsError.domain == NSURLErrorDomain &&
            (nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotConnectToHost)

        if isNetworkError {
            if let resumeDataFromError = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                resumeData = resumeDataFromError
                print("Resume data saved for future retry")
            }

            Task { @MainActor [weak self] in
                self?.retryDownload()
            }
        } else {
            print("Non-recoverable error: \(error.localizedDescription)")
            Task { @MainActor [weak self] in
                guard let self else { return }
                isDownloading = false
                isRetrying = false
                resumeData = nil
                retryCount = 0
                retryTimer?.invalidate()
                retryTimer = nil
                stopAccessingSecurityScope()
                manager?.downloadFailed(self)
            }
        }
    }
}

// MARK: - MultiDownloadManager

/// Manages multiple simultaneous downloads (up to 3)
@MainActor
class MultiDownloadManager: ObservableObject {
    static let shared = MultiDownloadManager()
    static let maxConcurrentDownloads = 3

    @Published var activeDownloads: [DownloadItem] = []
    @Published var completedDownloads: [DownloadItem] = []

    var canStartNewDownload: Bool {
        activeDownloads.count < MultiDownloadManager.maxConcurrentDownloads
    }

    var activeDownloadCount: Int {
        activeDownloads.count
    }

    /// Check if a file is already being downloaded
    func isDownloading(filename: String) -> Bool {
        activeDownloads.contains { $0.filename == filename }
    }

    /// Start a new download if slots are available
    func startDownload(url: URL?, filename: String, replacing: Bool = false) throws -> DownloadItem? {
        guard canStartNewDownload else {
            return nil
        }

        // Check if this file is already being downloaded
        if isDownloading(filename: filename) {
            print("File \(filename) is already being downloaded.")
            return nil
        }

        let downloadItem = DownloadItem()
        downloadItem.filename = filename
        downloadItem.manager = self

        activeDownloads.append(downloadItem)
        updateDockProgressStyle()

        try downloadItem.download(url: url, replacing: replacing)

        return downloadItem
    }

    /// Called when a download completes successfully
    func downloadCompleted(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
            activeDownloads.remove(at: index)
        }
        completedDownloads.append(item)
        updateDockProgress()
    }

    /// Called when a download is cancelled
    func downloadCancelled(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
            activeDownloads.remove(at: index)
        }
        updateDockProgress()
    }

    /// Called when a download fails
    func downloadFailed(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.id == item.id }) {
            activeDownloads.remove(at: index)
        }
        updateDockProgress()
    }

    /// Clear a completed download from the list
    func clearCompleted(_ item: DownloadItem) {
        if let index = completedDownloads.firstIndex(where: { $0.id == item.id }) {
            completedDownloads.remove(at: index)
        }
    }

    /// Clear all completed downloads
    func clearAllCompleted() {
        completedDownloads.removeAll()
    }

    /// Update dock progress based on all active downloads
    func updateDockProgress() {
        if activeDownloads.isEmpty {
            DockProgress.progress = 0.0
        } else {
            let totalProgress = activeDownloads.reduce(0.0) { $0 + $1.progress }
            let averageProgress = totalProgress / Double(activeDownloads.count)
            DockProgress.progress = averageProgress
        }
    }

    /// Update dock progress style to show download count
    private func updateDockProgressStyle() {
        DockProgress.style = .badge(color: .blue, badgeValue: { self.activeDownloads.count })
    }
}
