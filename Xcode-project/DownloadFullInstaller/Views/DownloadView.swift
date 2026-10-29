//
//  DownloadView.swift
//

import SwiftUI

struct DownloadItemView: View {
    @ObservedObject var downloadItem: DownloadItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Text(downloadItem.filename ?? "")
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(NSLocalizedString("Cancel", comment: "")) {
                    downloadItem.cancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(
                    String(
                        format: NSLocalizedString(
                            "Cancel %@ download",
                            comment: ""
                        ),
                        downloadItem.filename ?? ""
                    )
                )
            }
            ProgressView(value: downloadItem.progress)
            HStack {
                if downloadItem.isRetrying {
                    Text(
                        NSLocalizedString(
                            "Retrying download...",
                            comment: "Retrying a download"
                        )
                    )
                } else {
                    Text(downloadItem.progressString)
                }
                Spacer()
                Text(
                    downloadItem.progress,
                    format: .percent.precision(.fractionLength(0))
                )
                .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .glassSubtle(cornerRadius: 12)
    }
}

struct CompletedDownloadItemView: View {
    @ObservedObject var downloadItem: DownloadItem
    @ObservedObject var manager: MultiDownloadManager

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(
                String(
                    format: NSLocalizedString("Downloaded %@", comment: ""),
                    downloadItem.filename ?? ""
                )
            )
            .lineLimit(1)
            .truncationMode(.middle)
            Spacer()
            Button(NSLocalizedString("Show in Finder", comment: "")) {
                downloadItem.revealInFinder()
            }
            Button(action: { manager.clearCompleted(downloadItem) }) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(NSLocalizedString("Dismiss", comment: ""))
        }
        .padding(12)
        .glassSubtle(cornerRadius: 12)
    }
}

struct DownloadView: View {
    @ObservedObject private var manager = MultiDownloadManager.shared
    @State private var activeAlert: AppAlertType?

    private var hasDownloads: Bool {
        !manager.activeDownloads.isEmpty || !manager.completedDownloads.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(
                    NSLocalizedString(
                        "Downloads",
                        comment: "Download queue heading"
                    ),
                    systemImage: "arrow.down.to.line"
                )
                .font(.headline)
                Spacer()
                Text(
                    "\(manager.activeDownloadCount) / \(MultiDownloadManager.maxConcurrentDownloads)"
                )
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                    NSLocalizedString(
                        "Active downloads",
                        comment: "Active download count"
                    )
                )
            }
            if hasDownloads {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(manager.activeDownloads) { item in
                            DownloadItemView(downloadItem: item)
                        }
                        ForEach(manager.completedDownloads) { item in
                            CompletedDownloadItemView(
                                downloadItem: item,
                                manager: manager
                            )
                        }
                    }
                    .padding(2)
                }
                .frame(
                    height: min(
                        CGFloat(
                            manager.activeDownloads.count * 104 + manager
                                .completedDownloads.count * 56 + 4
                        ),
                        220
                    )
                )
            } else {
                Text(
                    NSLocalizedString(
                        "No active downloads",
                        comment: "Empty download queue"
                    )
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .onChange(of: manager.errorMessage) {
            if let message = manager.errorMessage {
                activeAlert = .downloadError(message: message)
                manager.errorMessage = nil
            }
        }
        .appAlert(item: $activeAlert)
    }
}
