//
//  SettingsView.swift
//
//  Created on 2026-01-18
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(Prefs.key(.downloadPath)) var downloadPath: String = ""
    @State private var showingDownloadPathPicker = false
    @State private var displayPath: String = ""
    @Environment(\.dismiss) var dismiss

    /// Update the display path for UI
    /// This checks the file system and should only be called after sandbox is initialized
    private func updateDisplayPath() {
        var path = downloadPath
        // If path is empty, show the default Downloads folder
        if path.isEmpty {
            if let defaultPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path {
                path = defaultPath
            }
        }
        // Replace home directory with tilde if applicable
        if path.hasPrefix(NSHomeDirectory()) {
            displayPath = path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        } else {
            displayPath = path
        }
    }

    var body: some View {
        ZStack {
            // Frosted glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.12))
                            .frame(width: 50, height: 50)
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.blue)
                    }

                    Text(NSLocalizedString("Settings", comment: "Settings window title"))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding(.top, 6)
                .padding(.bottom, 20)

                Divider()
                    .padding(.horizontal, 20)

                // Download folder section
                VStack(alignment: .leading, spacing: 14) {
                    Label {
                        Text(NSLocalizedString("Download Location", comment: "Download location label"))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.blue)
                    }

                    // Current path card
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.blue.opacity(0.8))

                        Text(displayPath)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                    Button(action: {
                        showingDownloadPathPicker = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder.badge.plus")
                            Text(NSLocalizedString("Select Download Folder", comment: ""))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .help(NSLocalizedString("Choose where to save downloaded installers", comment: ""))
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 20)

//                Spacer()

                Divider()
                    .padding(.horizontal, 20)

                // Close button
                HStack {
                    Spacer()
                    Button(NSLocalizedString("Close", comment: "Close button")) {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }
        }
        .frame(width: 400, height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            // Update display path after view appears, ensuring sandbox is fully initialized
            updateDisplayPath()
        }
        .onChange(of: downloadPath) {
            updateDisplayPath()
        }
        .fileImporter(
            isPresented: $showingDownloadPathPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let selectedURL = urls.first {
                    // Start accessing security-scoped resource
                    _ = selectedURL.startAccessingSecurityScopedResource()

                    // Save the path and bookmark using Prefs
                    Prefs.saveDownloadURL(selectedURL)

                    // Update the local @AppStorage variable for UI display
                    downloadPath = selectedURL.path

                    // Stop accessing security-scoped resource (bookmark will restore it when needed)
                    selectedURL.stopAccessingSecurityScopedResource()

                    print("Download path set to: \(selectedURL.path)")
                }
            case let .failure(error):
                print("Error selecting folder: \(error.localizedDescription)")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
