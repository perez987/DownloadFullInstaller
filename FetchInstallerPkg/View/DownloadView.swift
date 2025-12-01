	//
	//  DownloadView.swift
	//
	//  Created by Armin Briegel on 2021-06-15
	//  Modified by Emilio P Egido on 2025-09-23
	//

import SwiftUI

// MARK: - Single Download Item View
struct DownloadItemView: View {
	@ObservedObject var downloadItem: DownloadItem
	
	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			HStack {
				Text(" ")
				if downloadItem.isRetrying {
					Text(String(format: NSLocalizedString("Retrying download of InstallAssistant.pkg...", comment: "")))
				} else {
					Text(String(format: NSLocalizedString("Downloading %@", comment: ""), downloadItem.filename ?? "InstallAssistant.pkg"))
				}
				Spacer()
				Text(downloadItem.progressString)
					.font(.footnote)
					.lineLimit(1)
					.truncationMode(.middle)
				Text(" ")
			}
			HStack {
				Text(" ")
				ProgressView(value: downloadItem.progress)
				Button(action: { downloadItem.cancel() }) {
					Image(systemName: "xmark.circle.fill").accentColor(.gray)
						.help(String(format: NSLocalizedString("Cancel %@ download", comment: ""), downloadItem.filename ?? "InstallAssistant.pkg"))
				}.buttonStyle(.borderless)
				Text(" ")
			}
		}
	}
}

// MARK: - Completed Download Item View
struct CompletedDownloadItemView: View {
	@ObservedObject var downloadItem: DownloadItem
	@ObservedObject var manager: MultiDownloadManager
	
	var body: some View {
		HStack {
			Text(String(format: NSLocalizedString("Downloaded %@", comment: ""), downloadItem.filename ?? "InstallAssistant.pkg"))
				.padding(.vertical, 6)
			Spacer()

			if #available(macOS 26.0, *) {
				Button(action: {
					downloadItem.revealInFinder()
				})
				{ Text(NSLocalizedString("Show in Finder", comment: ""))
						.help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
				}
			}
			else {
				Button(action: {
					downloadItem.revealInFinder()
				}) {
					Image(systemName: "magnifyingglass")
					Text(NSLocalizedString("Show in Finder", comment: ""))
						.help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
				}
			}
			
			Button(action: {
				manager.clearCompleted(downloadItem)
			}) {
				Image(systemName: "xmark.circle.fill").accentColor(.gray)
					.help(NSLocalizedString("Dismiss", comment: ""))
			}.buttonStyle(.borderless)
		}
	}
}

// MARK: - Multi Download View
struct DownloadView: View {
	@StateObject var multiDownloadManager = MultiDownloadManager.shared
	// Keep reference to old download manager for backward compatibility during transition
	@StateObject var downloadManager = DownloadManager.shared

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			// Show completed downloads first (they appear at the top)
			ForEach(multiDownloadManager.completedDownloads) { item in
				CompletedDownloadItemView(downloadItem: item, manager: multiDownloadManager)
					.liquidGlass(intensity: .medium)
			}
			
			// Show active downloads (growing upward means new ones appear at the bottom)
			ForEach(multiDownloadManager.activeDownloads) { item in
				DownloadItemView(downloadItem: item)
					.liquidGlass(intensity: .medium)
					.multilineTextAlignment(.leading)
			}
			
			// Backward compatibility: Show old single download manager if it's downloading
			// This handles any downloads that were started before the multi-download manager was used
			if downloadManager.isDownloading && multiDownloadManager.activeDownloads.isEmpty {
				VStack(alignment: .leading) {
					HStack {
						Text(" ")
						if downloadManager.isRetrying {
							Text(String(format: NSLocalizedString("Retrying download of InstallAssistant.pkg...", comment: "")))
						} else {
							Text(String(format: NSLocalizedString("Downloading %@", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
						}
						Spacer()
						Text(downloadManager.progressString)
							.font(.footnote)
							.lineLimit(1)
							.truncationMode(.middle)
						Text(" ")
					}
					HStack {
						Text(" ")
						ProgressView(value: downloadManager.progress)
						Button(action: { downloadManager.cancel() }) {
							Image(systemName: "xmark.circle.fill").accentColor(.gray)
								.help(String(format: NSLocalizedString("Cancel %@ download", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
						}.buttonStyle(.borderless)
						Text(" ")
					}
				}
				.liquidGlass(intensity: .medium)
				.multilineTextAlignment(.leading)
			}
			
			// Backward compatibility: Show old single download manager completion
			if downloadManager.isComplete && multiDownloadManager.completedDownloads.isEmpty {
				HStack {
					Text(String(format: NSLocalizedString("Downloaded %@", comment: ""), downloadManager.filename ?? "InstallAssistant.pkg"))
						.padding(.vertical, 6)
					Spacer()

					if #available(macOS 26.0, *) {
						Button(action: {
							downloadManager.revealInFinder()
						})
						{ Text(NSLocalizedString("Show in Finder", comment: ""))
								.help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
						}
					}
					else {
						Button(action: {
							downloadManager.revealInFinder()
						}) {
							Image(systemName: "magnifyingglass")
							Text(NSLocalizedString("Show in Finder", comment: ""))
								.help(NSLocalizedString("Show the installer in the Downloads folder", comment: ""))
						}
					}
				}
				.liquidGlass(intensity: .medium)
			}
		}
	}
}

struct DownloadView_Previews: PreviewProvider {
	static var previews: some View {
		DownloadView()
	}
}
