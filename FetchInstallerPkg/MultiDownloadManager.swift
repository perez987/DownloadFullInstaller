//
//  MultiDownloadManager.swift
//
//  Created by Copilot on 2025-12-01
//  Manages multiple simultaneous downloads (up to 3)
//

import AppKit
import DockProgress
import Foundation

// MARK: - DownloadItem
/// Represents a single download instance with its own progress tracking
class DownloadItem: NSObject, ObservableObject, Identifiable {
    let id = UUID()
    
    @Published var downloadURL: URL?
    @Published var localURL: URL?
    @Published var isDownloading = false
    @Published var progress: Double = 0.0
    @Published var progressString: String = ""
    @Published var isComplete = false
    @Published var filename: String?
    @Published var isRetrying = false
    
    private var resumeData: Data?
    private var retryCount = 0
    private var maxRetries = 100
    private var retryTimer: Timer?
    
    lazy var urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
    var downloadTask: URLSessionDownloadTask?
    var byteFormatter = ByteCountFormatter()
    
    // Reference to parent manager for notifications
    weak var manager: MultiDownloadManager?
    
    var fileExists: Bool {
        let destination = Prefs.downloadURL
        if filename != nil {
            let file = destination.appendingPathComponent(filename!)
            return FileManager.default.fileExists(atPath: file.path)
        } else {
            return false
        }
    }
    
    func download(url: URL?, replacing: Bool = false) throws {
        downloadURL = url
        isComplete = false
        byteFormatter.countStyle = .file
        
        if replacing {
            let destination = Prefs.downloadURL
            let suggestedFilename = filename ?? "InstallerAssistant.pkg"
            let file = destination.appendingPathComponent(suggestedFilename)
            try FileManager.default.removeItem(at: file)
            resumeData = nil
        }
        
        startDownload()
    }
    
    private func startDownload() {
        guard let url = downloadURL else { return }
        
        isDownloading = true
        if !isRetrying {
            retryCount = 0
        }
        isRetrying = false
        
        // Update dock progress
        manager?.updateDockProgress()
        
        if let resumeData = resumeData {
            downloadTask = urlSession.downloadTask(withResumeData: resumeData)
            print("### Resuming download of \(filename ?? "InstallerAssistant.pkg")")
        } else {
            downloadTask = urlSession.downloadTask(with: url)
            progress = 0.0
            localURL = nil
            print("### Starting download of \(filename ?? "InstallerAssistant.pkg")")
        }
        
        downloadTask?.resume()
    }
    
    func cancel() {
        if isDownloading && downloadTask != nil {
            downloadTask?.cancel { [weak self] resumeDataOrNil in
                DispatchQueue.main.async {
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
            manager?.downloadCancelled(self)
        }
        print("### Cancelled download of \(filename ?? "InstallerAssistant.pkg")")
    }
    
    private func retryDownload() {
        guard retryCount < maxRetries else {
            print("### Max retry attempts reached. Download failed.")
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.resumeData = nil
                self.manager?.downloadFailed(self)
            }
            return
        }
        
        retryCount += 1
        let retryDelay: Double = 5
        
        print("### Connection lost. Retrying download in \(Int(retryDelay))\"... (Attempt \(retryCount)/\(maxRetries))")
        
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
            let destination = Prefs.downloadURL.path
            NSWorkspace.shared.selectFile(localURL?.path, inFileViewerRootedAtPath: destination)
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadItem: URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destination = Prefs.downloadURL
        let suggestedFilename = filename ?? downloadTask.response?.suggestedFilename ?? UUID().uuidString
        
        do {
            let file = destination.appendingPathComponent(suggestedFilename)
            let newURL = try FileManager.default.replaceItemAt(file, withItemAt: location)
            print("### Finished download of \(filename ?? "InstallerAssistant.pkg")")
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.localURL = newURL
                self.isComplete = true
                self.resumeData = nil
                self.retryCount = 0
                self.retryTimer?.invalidate()
                self.retryTimer = nil
                self.manager?.downloadCompleted(self)
            }
        } catch {
            print("### Error: \(error.localizedDescription)")
        }
    }
    
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progressString = "\(self.byteFormatter.string(fromByteCount: totalBytesWritten))/\(self.byteFormatter.string(fromByteCount: totalBytesExpectedToWrite))"
            self.manager?.updateDockProgress()
        }
    }
    
    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("### Download resumed at offset: \(fileOffset) bytes")
        DispatchQueue.main.async {
            self.progress = Double(fileOffset) / Double(expectedTotalBytes)
            self.progressString = "\(self.byteFormatter.string(fromByteCount: fileOffset))/\(self.byteFormatter.string(fromByteCount: expectedTotalBytes))"
            self.manager?.updateDockProgress()
        }
    }
}

// MARK: - URLSessionTaskDelegate
extension DownloadItem: URLSessionTaskDelegate {
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        
        print("### Download error: \(error.localizedDescription)")
        
        let nsError = error as NSError
        let isNetworkError = nsError.domain == NSURLErrorDomain &&
        (nsError.code == NSURLErrorNotConnectedToInternet ||
         nsError.code == NSURLErrorNetworkConnectionLost ||
         nsError.code == NSURLErrorTimedOut ||
         nsError.code == NSURLErrorCannotConnectToHost)
        
        if isNetworkError {
            if let resumeDataFromError = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                self.resumeData = resumeDataFromError
                print("### Resume data saved for future retry")
            }
            
            DispatchQueue.main.async {
                self.retryDownload()
            }
        } else {
            print("### Non-recoverable download error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isRetrying = false
                self.resumeData = nil
                self.retryCount = 0
                self.retryTimer?.invalidate()
                self.retryTimer = nil
                self.manager?.downloadFailed(self)
            }
        }
    }
}

// MARK: - MultiDownloadManager
/// Manages multiple simultaneous downloads (up to 3)
class MultiDownloadManager: ObservableObject {
    static let shared = MultiDownloadManager()
    static let maxConcurrentDownloads = 3
    
    @Published var activeDownloads: [DownloadItem] = []
    @Published var completedDownloads: [DownloadItem] = []
    
    var canStartNewDownload: Bool {
        return activeDownloads.count < MultiDownloadManager.maxConcurrentDownloads
    }
    
    var activeDownloadCount: Int {
        return activeDownloads.count
    }
    
    /// Check if a file is already being downloaded
    func isDownloading(filename: String) -> Bool {
        return activeDownloads.contains { $0.filename == filename }
    }
    
    /// Start a new download if slots are available
    func startDownload(url: URL?, filename: String, replacing: Bool = false) throws -> DownloadItem? {
        guard canStartNewDownload else {
            print("### Maximum concurrent downloads reached (3). Please wait for a download to complete.")
            return nil
        }
        
        // Check if this file is already being downloaded
        if isDownloading(filename: filename) {
            print("### File \(filename) is already being downloaded.")
            return nil
        }
        
        let downloadItem = DownloadItem()
        downloadItem.filename = filename
        downloadItem.manager = self
        
        DispatchQueue.main.async {
            self.activeDownloads.append(downloadItem)
            self.updateDockProgressStyle()
        }
        
        try downloadItem.download(url: url, replacing: replacing)
        
        return downloadItem
    }
    
    /// Called when a download completes successfully
    func downloadCompleted(_ item: DownloadItem) {
        DispatchQueue.main.async {
            if let index = self.activeDownloads.firstIndex(where: { $0.id == item.id }) {
                self.activeDownloads.remove(at: index)
            }
            self.completedDownloads.append(item)
            self.updateDockProgress()
        }
    }
    
    /// Called when a download is cancelled
    func downloadCancelled(_ item: DownloadItem) {
        DispatchQueue.main.async {
            if let index = self.activeDownloads.firstIndex(where: { $0.id == item.id }) {
                self.activeDownloads.remove(at: index)
            }
            self.updateDockProgress()
        }
    }
    
    /// Called when a download fails
    func downloadFailed(_ item: DownloadItem) {
        DispatchQueue.main.async {
            if let index = self.activeDownloads.firstIndex(where: { $0.id == item.id }) {
                self.activeDownloads.remove(at: index)
            }
            self.updateDockProgress()
        }
    }
    
    /// Clear a completed download from the list
    func clearCompleted(_ item: DownloadItem) {
        DispatchQueue.main.async {
            if let index = self.completedDownloads.firstIndex(where: { $0.id == item.id }) {
                self.completedDownloads.remove(at: index)
            }
        }
    }
    
    /// Clear all completed downloads
    func clearAllCompleted() {
        DispatchQueue.main.async {
            self.completedDownloads.removeAll()
        }
    }
    
    /// Update dock progress based on all active downloads
    func updateDockProgress() {
        DispatchQueue.main.async {
            if self.activeDownloads.isEmpty {
                DockProgress.progress = 0.0
            } else {
                // Calculate average progress of all active downloads
                let totalProgress = self.activeDownloads.reduce(0.0) { $0 + $1.progress }
                let averageProgress = totalProgress / Double(self.activeDownloads.count)
                DockProgress.progress = averageProgress
            }
        }
    }
    
    /// Update dock progress style to show download count
    private func updateDockProgressStyle() {
        DispatchQueue.main.async {
            DockProgress.style = .badge(color: .blue, badgeValue: { self.activeDownloads.count })
        }
    }
}
