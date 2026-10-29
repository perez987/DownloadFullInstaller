//
//  LegacyDownloadView.swift
//

import SwiftUI

struct LegacyVersionRow: View {
    let version: LegacyMacOSVersion
    @ObservedObject private var downloadManager = MultiDownloadManager.shared
    @State private var activeAlert: AppAlertType?

    private var filename: String {
        version.filename
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(version.name)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("macOS \(version.name)")
                    .font(.title3.weight(.semibold))
                Text("\(version.version) · DMG")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: downloadLegacyVersion) {
                Label(
                    NSLocalizedString("Download", comment: "Download button"),
                    systemImage: "arrow.down.circle"
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(downloadManager.isDownloading(filename: filename))
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
        .contextMenu {
            Button(
                NSLocalizedString(
                    "Copy Download URL",
                    comment: "Copy legacy download URL"
                )
            ) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(version.url, forType: .string)
            }
        }
        .appAlert(item: $activeAlert) { alert in
            if case .replaceFile = alert { startDownload(replacing: true) }
        }
    }

    private func downloadLegacyVersion() {
        guard downloadManager.canStartNewDownload else {
            activeAlert = .maxDownloads
            return
        }
        let accessStarted = Prefs.startAccessingDownloadURL()
        defer { Prefs.stopAccessingDownloadURL(accessStarted) }
        let file = Prefs.downloadURL.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: file.path) {
            activeAlert = .replaceFile(filename: filename)
        } else {
            startDownload(replacing: false)
        }
    }

    private func startDownload(replacing: Bool) {
        do {
            _ = try downloadManager.startDownload(
                url: URL(string: version.url),
                filename: filename,
                replacing: replacing
            )
        } catch {
            activeAlert = .downloadError(message: error.localizedDescription)
        }
    }
}
