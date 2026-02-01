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
    
    // Update the display path for UI
    // This checks the file system and should only be called after sandbox is initialized
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
        VStack(spacing: 10) {
            Text(NSLocalizedString("Settings", comment: "Settings window title"))
                .font(.headline)
                .padding(.top)
            
            Divider()
            
            // Download folder selection
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("Download Location", comment: "Download location label"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button(action: {
                        showingDownloadPathPicker = true
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text(NSLocalizedString("Select Download Folder", comment: ""))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .help(NSLocalizedString("Choose where to save downloaded installers", comment: ""))
                    
                    Spacer()
                }
                
                // Show current download path
                Text(displayPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }
            .padding(.horizontal)
            
            Spacer()
                .frame(height: 5)
            
            // Close button
            HStack {
                Spacer()
                Button(NSLocalizedString("Close", comment: "Close button")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 400, height: 220)
        .onAppear {
            // Update display path after view appears, ensuring sandbox is fully initialized
            updateDisplayPath()
        }
        .onChange(of: downloadPath) { _ in
            // Update display path when download path changes
            updateDisplayPath()
        }
        .fileImporter(
            isPresented: $showingDownloadPathPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
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
            case .failure(let error):
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
