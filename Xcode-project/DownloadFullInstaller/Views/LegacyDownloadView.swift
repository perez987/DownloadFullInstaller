//
//  LegacyDownloadView.swift
//

import SwiftUI

struct LegacyVersionRow: View {
    let version: LegacyMacOSVersion
    @ObservedObject private var downloadManager = MultiDownloadManager.shared
    @State private var activeAlert: AppAlertType?
    @State private var size: Int64?

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
                HStack(spacing: 8) {
                    Text("\(version.version) · DMG")
                    if let size {
                        Text(Prefs.byteFormatter.string(fromByteCount: size))
                    }
                }
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
        .task(id: version.url) { size = await fetchSize() }
        .appAlert(item: $activeAlert) { alert in
            if case .replaceFile = alert { startDownload(replacing: true) }
        }
    }

    /// Legacy sizes are not in a catalog, so read Content-Length from the CDN.
    private func fetchSize() async -> Int64? {
        guard let url = URL(string: version.url) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        guard let (_, response) = try? await URLSession.shared.data(for: request),
            response.expectedContentLength > 0
        else { return nil }
        return response.expectedContentLength
    }

    private func downloadLegacyVersion() {
        guard downloadManager.canStartNewDownload else {
            activeAlert = .maxDownloads
            return
        }
        if let shortage = DiskSpace.shortage(forDownloadSize: size ?? 0) {
            activeAlert = shortage
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
