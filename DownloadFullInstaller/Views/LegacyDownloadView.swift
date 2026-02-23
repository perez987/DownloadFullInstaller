//
//  LegacyDownloadView.swift
//
//  Created on 2026-01-27
//

import SwiftUI

struct LegacyDownloadView: View {
    @StateObject private var downloadManager = LegacyDownloadManager()
    @Environment(\.dismiss) private var dismiss

    private var shouldShowDownloadSection: Bool {
        downloadManager.isDownloading || downloadManager.isComplete || downloadManager.errorMessage != nil
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text(NSLocalizedString("Legacy macOS Installers", comment: "Legacy download window title"))
                .font(.title2)
                .bold()
                .padding(.top, 20)

            Text(NSLocalizedString("Download legacy macOS installers (10.7 - 10.12)", comment: "Legacy download description"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            // List of legacy versions
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(LegacyMacOSVersion.allVersions) { version in
                        LegacyVersionRow(
                            version: version,
                            downloadManager: downloadManager
                        )
                    }
                }
                .padding(.horizontal)
            }
//            .frame(height: shouldShowDownloadSection ? 280 : 344)
            .frame(height: 312)

            Spacer(minLength: 0)

            // Download progress section
            if shouldShowDownloadSection {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    if let errorMessage = downloadManager.errorMessage {
                        // Error message
                        HStack {
//                            Image(systemName: "exclamationmark.triangle.fill")
//                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.primary)
                                .padding(.vertical, 6)
                            Spacer()

                            Button(action: {
                                downloadManager.clearComplete()
                            }) {
                                Image(systemName: "xmark.circle.fill").accentColor(.gray)
                                    .help(NSLocalizedString("Dismiss", comment: ""))
                            }.buttonStyle(.borderless)
                        }
                    } else if downloadManager.isComplete {
                        HStack {
                            Text(String(format: NSLocalizedString("Downloaded %@", comment: ""), downloadManager.filename ?? ""))
                                .padding(.vertical, 6)
                            Spacer()

                            Button(action: {
                                downloadManager.revealInFinder()
                            }) {
                                Image(systemName: "magnifyingglass")
                                Text(NSLocalizedString("Show in Finder", comment: ""))
                            }

                            Button(action: {
                                downloadManager.clearComplete()
                            }) {
                                Image(systemName: "xmark.circle.fill").accentColor(.gray)
                                    .help(NSLocalizedString("Dismiss", comment: ""))
                            }.buttonStyle(.borderless)
                        }
                    } else {
                        HStack {
//                            Text(String(format: NSLocalizedString("Downloading %@", comment: ""), downloadManager.filename ?? ""))
                            Text(String(format: NSLocalizedString("%@", comment: ""), downloadManager.filename ?? ""))
                            Spacer()
                            Text(downloadManager.progressString)
                                .font(.footnote)
                        }

                        HStack {
                            ProgressView(value: downloadManager.progress)
                            Button(action: {
                                downloadManager.cancel()
                            }) {
                                Image(systemName: "xmark.circle.fill").accentColor(.gray)
                                    .help(String(format: NSLocalizedString("Cancel %@ download", comment: ""), downloadManager.filename ?? ""))
                            }.buttonStyle(.borderless)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Close button
            HStack {
                Spacer()
                Button(NSLocalizedString("Close", comment: "")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom], 32)
        }
        .frame(width: 400, height: 580)
    }
}

struct LegacyVersionRow: View {
    let version: LegacyMacOSVersion
    @ObservedObject var downloadManager: LegacyDownloadManager

    var body: some View {
        HStack {
            // Icon for legacy macOS version
            Image(version.name)
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text("macOS \(version.name) \(version.version)")
                .font(.headline)

            Spacer()

            Button(action: {
                downloadLegacyVersion()
            }) {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
            }
            .help(String(format: NSLocalizedString("Download macOS %@ %@", comment: ""), version.name, version.version))
            .disabled(downloadManager.isDownloading)
            .buttonStyle(.borderless)
        }
        .frame(width: 320.0, height: 32.0)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    func downloadLegacyVersion() {
        guard let url = URL(string: version.url) else { return }

        // Check if file already exists
        let destination = Prefs.downloadURL
        // Generate filename that matches the downloaded file format
        let urlFilename = url.lastPathComponent // Gets the actual filename from URL (e.g., "InstallOS.dmg")
        let versionSuffix = version.name.replacingOccurrences(of: " ", with: "_") + "_" + version.version
        let filename = urlFilename.replacingOccurrences(of: ".dmg", with: "_\(versionSuffix).dmg")
        let file = destination.appendingPathComponent(filename)

        // Start accessing security-scoped resource for file check (only if needed)
        let accessStarted = Prefs.startAccessingDownloadURL()
        defer {
            Prefs.stopAccessingDownloadURL(accessStarted)
        }

        if FileManager.default.fileExists(atPath: file.path) {
            // Show replace alert
            let alert = NSAlert()
            alert.messageText = String(format: NSLocalizedString("%@ already exists. Do you want to replace it?", comment: ""), filename)
            alert.informativeText = NSLocalizedString("A file with the same name already exists in that location. Replacing it will overwrite its current contents.", comment: "")
            alert.addButton(withTitle: NSLocalizedString("Replace", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            alert.alertStyle = .warning

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                downloadManager.download(url: url, filename: filename, replacing: true)
            }
        } else {
            downloadManager.download(url: url, filename: filename, replacing: false)
        }
    }
}

// Legacy Download Manager
class LegacyDownloadManager: NSObject, ObservableObject {
    @Published var isDownloading = false
    @Published var isComplete = false
    @Published var progress: Double = 0.0
    @Published var progressString: String = ""
    @Published var filename: String?
    @Published var errorMessage: String?

    // User-Agent to match Safari's behavior for CDN compatibility
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private var downloadTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        // Set a custom User-Agent to match Safari's behavior
        config.httpAdditionalHeaders = ["User-Agent": LegacyDownloadManager.userAgent]
        // Set reasonable timeouts
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var byteFormatter = ByteCountFormatter()
    private var localURL: URL?

    // Security-scoped resource tracking
    private var destinationURL: URL?
    private var isAccessingSecurityScope = false

    func download(url: URL, filename: String, replacing: Bool) {
        self.filename = filename
        isComplete = false
        errorMessage = nil
        byteFormatter.countStyle = .file

        // Get destination URL and start accessing security-scoped resource
        let destination = Prefs.downloadURL
        destinationURL = destination
        if !isAccessingSecurityScope {
            isAccessingSecurityScope = Prefs.startAccessingDownloadURL()
        }

        if replacing {
            let file = destination.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: file)
        }

        isDownloading = true
        progress = 0.0
        progressString = ""

//        print("Starting legacy download: \(url.absoluteString)")
        print("Starting legacy download: \(filename)")
        downloadTask = urlSession.downloadTask(with: url)
        downloadTask?.resume()
    }

    func cancel() {
        downloadTask?.cancel()
        isDownloading = false
        progress = 0.0
        errorMessage = nil
        stopAccessingSecurityScope()
    }

    func clearComplete() {
        isComplete = false
        localURL = nil
        filename = nil
        errorMessage = nil
    }

    func revealInFinder() {
        if isComplete, let localURL = localURL {
            let destination = Prefs.downloadURL

            // Start accessing security-scoped resource for Finder reveal (only if needed)
            let accessStarted = Prefs.startAccessingDownloadURL()
            defer {
                Prefs.stopAccessingDownloadURL(accessStarted)
            }

            NSWorkspace.shared.selectFile(localURL.path, inFileViewerRootedAtPath: destination.path)
        }
    }

    private func stopAccessingSecurityScope() {
        if isAccessingSecurityScope {
            Prefs.stopAccessingDownloadURL(isAccessingSecurityScope)
            isAccessingSecurityScope = false
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension LegacyDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destination = destinationURL else {
            print("Error: No destination URL available")
            stopAccessingSecurityScope()
            return
        }

        guard let filename = filename else { return }

        do {
            let file = destination.appendingPathComponent(filename)

            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: file.path) {
                try FileManager.default.removeItem(at: file)
            }

            // Move the downloaded file to the destination
            try FileManager.default.moveItem(at: location, to: file)

            print("Finished download of \(filename)")
            stopAccessingSecurityScope()

            DispatchQueue.main.async {
                self.isDownloading = false
                self.isComplete = true
                self.localURL = file
            }
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            stopAccessingSecurityScope()

            // Extract folder name from destination path for error message
            let folderName = destination.lastPathComponent
            let errorMsg = String(format: NSLocalizedString("The file '%@' could not be saved to the '%@' folder. Error: %@", comment: "Download save error"), filename, folderName, error.localizedDescription)

            DispatchQueue.main.async {
                self.isDownloading = false
                self.isComplete = false
                self.errorMessage = errorMsg
            }
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progressString = "\(self.byteFormatter.string(fromByteCount: totalBytesWritten))/\(self.byteFormatter.string(fromByteCount: totalBytesExpectedToWrite))"
        }
    }
}

// MARK: - URLSessionTaskDelegate

extension LegacyDownloadManager: URLSessionTaskDelegate {
    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }

        print("Legacy download error: \(error.localizedDescription)")

        // Check if this is a network error
        let nsError = error as NSError
        let isNetworkError = nsError.domain == NSURLErrorDomain &&
            (nsError.code == NSURLErrorNotConnectedToInternet ||
                nsError.code == NSURLErrorNetworkConnectionLost ||
                nsError.code == NSURLErrorTimedOut ||
                nsError.code == NSURLErrorCannotConnectToHost)

        var userFriendlyMessage = error.localizedDescription
        if isNetworkError {
            print("Network error detected for legacy download")
            userFriendlyMessage = NSLocalizedString("Network error: Please check your internet connection and try again.", comment: "")
        }

        // Stop accessing security-scoped resource on error
        stopAccessingSecurityScope()

        DispatchQueue.main.async {
            self.isDownloading = false
            self.isComplete = false
            self.progress = 0.0
            self.progressString = ""
            self.errorMessage = userFriendlyMessage
        }
    }
}
