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

struct MultipartDownloadItemView: View {
    @ObservedObject var group: MultipartDownloadGroup
    @ObservedObject private var coordinator = MultipartDownloadCoordinator
        .shared

    var body: some View {
        if group.isComplete {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(
                    String(
                        format: NSLocalizedString("Downloaded %@", comment: ""),
                        group.title
                    )
                )
                .lineLimit(1)
                .truncationMode(.middle)
                Spacer()
                Button(NSLocalizedString("Show in Finder", comment: "")) {
                    let access = Prefs.startAccessingDownloadURL()
                    defer { Prefs.stopAccessingDownloadURL(access) }
                    NSWorkspace.shared.activateFileViewerSelecting([
                        Prefs.downloadURL.appendingPathComponent(group.id)
                    ])
                }
                Button(action: { coordinator.dismiss(group) }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .accessibilityLabel(NSLocalizedString("Dismiss", comment: ""))
            }
            .padding(12)
            .glassSubtle(cornerRadius: 12)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text(group.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        coordinator.cancel(group)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(
                        String(
                            format: NSLocalizedString(
                                "Cancel %@ download",
                                comment: ""
                            ),
                            group.title
                        )
                    )
                }
                // Component progress is not published to this view, so refresh periodically.
                TimelineView(.periodic(from: .now, by: 0.2)) { _ in
                    let progress = group.progress
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: progress)
                        HStack {
                            if group.isRetrying {
                                Text(
                                    NSLocalizedString(
                                        "Retrying download...",
                                        comment: "Retrying a download"
                                    )
                                )
                            } else {
                                let formatter = Prefs.byteFormatter
                                Text(
                                    "\(formatter.string(fromByteCount: Int64(Double(group.totalSize) * progress)))/\(formatter.string(fromByteCount: Int64(group.totalSize)))"
                                )
                            }
                            Spacer()
                            Text(
                                progress,
                                format: .percent.precision(.fractionLength(0))
                            )
                            .monospacedDigit()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .glassSubtle(cornerRadius: 12)
        }
    }
}

struct DownloadView: View {
    @ObservedObject private var manager = MultiDownloadManager.shared
    @ObservedObject private var coordinator = MultipartDownloadCoordinator
        .shared
    @State private var activeAlert: AppAlertType?

    private var singleActive: [DownloadItem] {
        manager.activeDownloads.filter { $0.filename?.contains("/") != true }
    }

    private var singleCompleted: [DownloadItem] {
        manager.completedDownloads.filter { $0.filename?.contains("/") != true }
    }

    private var hasDownloads: Bool {
        !singleActive.isEmpty || !singleCompleted.isEmpty
            || !coordinator.groups.isEmpty
    }

    private var listHeight: CGFloat {
        let activeGroups: Int = coordinator.groups.filter { !$0.isComplete }
            .count
        let completedGroups: Int = coordinator.groups.filter { $0.isComplete }
            .count
        let activeRows: Int = (singleActive.count + activeGroups) * 104
        let completedRows: Int = (singleCompleted.count + completedGroups) * 56
        return min(CGFloat(activeRows + completedRows + 4), 220)
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
                        ForEach(coordinator.groups) { group in
                            MultipartDownloadItemView(group: group)
                        }
                        ForEach(singleActive) { item in
                            DownloadItemView(downloadItem: item)
                        }
                        ForEach(singleCompleted) { item in
                            CompletedDownloadItemView(
                                downloadItem: item,
                                manager: manager
                            )
                        }
                    }
                    .padding(2)
                }
                .frame(height: listHeight)
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
