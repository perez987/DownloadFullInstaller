//
//  DownloadManager.swift
//
//  Created by Armin Briegel on 2021-06-14
//  Modified by Emilio P Egido on 2025-09-23
//

import AppKit
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

lazy var urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
var downloadTask: URLSessionDownloadTask?
var byteFormatter = ByteCountFormatter()

    // Resume functionality properties
private var resumeData: Data?
private var retryCount = 0
private var maxRetries = 100
private var retryTimer: Timer?
@Published var isRetrying = false

static let shared = DownloadManager()

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
        // Store the URL for potential resume attempts
    downloadURL = url
    isComplete = false
    byteFormatter.countStyle = .file

    if replacing {
        let destination = Prefs.downloadURL
        let suggestedFilename = filename ?? "InstallerAssistant.pkg"
        let file = destination.appendingPathComponent(suggestedFilename)
        try FileManager.default.removeItem(at: file)
            // Clear resume data if replacing file
        resumeData = nil
    }

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

        // Try to resume from previous download if resume data exists
    if let resumeData = resumeData {
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

func cancel() {
    if isDownloading && downloadTask != nil {
        downloadTask?.cancel { [weak self] resumeDataOrNil in
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
        retryCount = 0
        retryTimer?.invalidate()
        retryTimer = nil
    }
    print("Download of \(filename ?? "InstallerAssistant.pkg") cancelled")
}

private func retryDownload() {
    guard retryCount < maxRetries else {
        print("Max retry attempts reached. Download failed.")
        DispatchQueue.main.async {
            self.isDownloading = false
            self.isRetrying = false
            self.resumeData = nil
        }
        return
    }

	retryCount += 1 // Number of resume attempts made

//    let retryDelay = pow(2.0, Double(retryCount)) // Exponential backoff: 2, 4, 8... seconds
	let retryDelay : Double = 5 // Retry interval 5 seconds

	print("Connection lost. Retrying download in \(Int(retryDelay)) seconds... (Attempt \(retryCount)/\(maxRetries))")
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
    let destination = Prefs.downloadURL

        // get the suggest file name or create a uuid string
    let suggestedFilename = filename ?? downloadTask.response?.suggestedFilename ?? UUID().uuidString

    do {
        let file = destination.appendingPathComponent(suggestedFilename)
        let newURL = try FileManager.default.replaceItemAt(file, withItemAt: location)
        print("Download of \(filename ?? "InstallerAssistant.pkg") finished")
        DispatchQueue.main.async {
            self.isDownloading = false
            self.isRetrying = false
            self.localURL = newURL
            self.isComplete = true
            self.resumeData = nil // Clear resume data on successful completion
            self.retryCount = 0
            self.retryTimer?.invalidate()
            self.retryTimer = nil
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    DispatchQueue.main.async {
        self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        self.progressString = "\(self.byteFormatter.string(fromByteCount: totalBytesWritten))/\(self.byteFormatter.string(fromByteCount: totalBytesExpectedToWrite))"
    }
}

    // Handle download resumption
func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    print("Download resumed at offset: \(fileOffset) bytes")
    DispatchQueue.main.async {
        self.progress = Double(fileOffset) / Double(expectedTotalBytes)
        self.progressString = "\(self.byteFormatter.string(fromByteCount: fileOffset))/\(self.byteFormatter.string(fromByteCount: expectedTotalBytes))"
		}
	}
}

// MARK: - URLSessionTaskDelegate methods for error handling
extension DownloadManager: URLSessionTaskDelegate {
func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error = error else { return }

//    print("Download error occurred: \(error.localizedDescription)")
	print("Download error occurred: the Internet connection has been lost")
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
            self.resumeData = resumeDataFromError
            print("Resume data saved for future retry")
        }

            // Attempt to retry the download
        DispatchQueue.main.async {
            self.retryDownload()
        }
    } else {
            // Non-recoverable error
        print("Non-recoverable download error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isDownloading = false
            self.isRetrying = false
            self.resumeData = nil
            self.retryCount = 0
            self.retryTimer?.invalidate()
            self.retryTimer = nil
        }
    }
}
}
