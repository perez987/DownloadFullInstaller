//
//  DownloadManager.swift
//
//  Created by Armin Briegel on 2021-06-14
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
        // reset the variables
        progress = 0.0
        isDownloading = true
        localURL = nil
        downloadURL = url
        isComplete = false

        byteFormatter.countStyle = .file

        if replacing {
            let destination = Prefs.downloadURL
            let suggestedFilename = filename ?? "InstallerAssistant.pkg"
            let file = destination.appendingPathComponent(suggestedFilename)
            try FileManager.default.removeItem(at: file)
        }

        if url != nil {
            downloadTask = urlSession.downloadTask(with: url!)
            downloadTask!.resume()
            print("Downloading \(filename ?? "InstallerAssistant.pkg")")
        }
    }

    func cancel() {
        if isDownloading && downloadTask != nil {
            downloadTask?.cancel()
            isDownloading = false
            localURL = nil
            downloadURL = nil
            progress = 0.0
        }
        print("Download of \(filename ?? "InstallerAssistant.pkg") cancelled")
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
                self.localURL = newURL
                self.isComplete = true
            }
        } catch {
            NSLog(error.localizedDescription)
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("urlSession -> didWriteData: \(totalBytesWritten)/\(totalBytesExpectedToWrite)")
        DispatchQueue.main.async {
            self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            self.progressString = "\(self.byteFormatter.string(fromByteCount: totalBytesWritten))/\(self.byteFormatter.string(fromByteCount: totalBytesExpectedToWrite))"
        }
    }
}
