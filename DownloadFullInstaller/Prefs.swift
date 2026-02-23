//
//  Prefs.swift
//
//  Created by Armin Briegel on 2021-06-15
// Modified by Emilio P Egido on 2026-01-18
//

import Foundation

enum Prefs {
    enum Key: String {
        case seedProgram = "SeedProgram"
        case osNameID = "OsNameID"
        case downloadPath = "DownloadPath"
        case downloadPathBookmark = "DownloadPathBookmark"
        case languageSelectionShown = "LanguageSelectionShown"
    }

    // Track whether we've already logged the stale bookmark message to avoid console spam
    private static let staleBookmarkLock = NSLock()
    private static var hasLoggedStaleBookmark = false

    static func key(_ key: Key) -> String {
        return key.rawValue
    }

    // Save user preferences (AppleLanguages, LanguageSelectionShown and downloadURL)
    static func registerDefaults() {
        var prefs = [String: Any]()
        prefs[Prefs.key(.seedProgram)] = SeedProgram.noSeed.rawValue
        prefs[Prefs.key(.osNameID)] = OsNameID.osAll.rawValue
        prefs[Prefs.key(.languageSelectionShown)] = false

        // Don't access file system during early initialization to avoid sandbox crash
        // The downloadPath property getter (lines 60-69) will lazily get the Downloads directory when needed

        UserDefaults.standard.register(defaults: prefs)
    }

    // Delete preferences plist file, the app will run as if it were the first time
    static func delPlist() {
        let fileManager = FileManager.default
        let directory = URL.libraryDirectory.appending(path: "Preferences").path()
        let documentURL = directory + "/perez987.DownloadFullInstaller.plist"
//            print("Preferences plist file: \(documentURL)")
        do {
            try fileManager.removeItem(atPath: documentURL)
            print("Preferences plist file deleted successfully")
        } catch {
            print("Error deleting Preferences plist file: \(error)")
        }
    }

    static var seedProgram: SeedProgram {
        let seedValue = UserDefaults.standard.string(forKey: Prefs.key(.seedProgram)) ?? ""
        return SeedProgram(rawValue: seedValue) ?? .noSeed
    }

    static var osNameID: OsNameID {
        let osValue = UserDefaults.standard.string(forKey: Prefs.key(.osNameID)) ?? ""
        return OsNameID(rawValue: osValue) ?? .osAll
    }

    static var downloadPath: String {
        let path = UserDefaults.standard.string(forKey: Prefs.key(.downloadPath)) ?? ""
        if path.isEmpty {
            // Return default Downloads directory if no custom path is set
            if let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                return downloadURL.path
            }
        }
        return path
    }

    static var downloadURL: URL {
        // Try to resolve from bookmark first (for custom folders with security-scoped access)
        if let bookmarkData = UserDefaults.standard.data(forKey: Prefs.key(.downloadPathBookmark)) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

                if isStale {
                    staleBookmarkLock.lock()
                    defer { staleBookmarkLock.unlock() }

                    if !hasLoggedStaleBookmark {
                        print("Bookmark is stale, will recreate on next folder selection")
                        hasLoggedStaleBookmark = true
                    }
                }

                // Return the URL without starting to access the security-scoped resource
                // Callers must explicitly call startAccessingSecurityScopedResource() when needed
                return url
            } catch {
                print("Error resolving bookmark: \(error.localizedDescription)")
            }
        }

        // Fallback to path-based URL
        let downloadURL = URL(fileURLWithPath: downloadPath)
        return downloadURL
    }

    /// Returns true if the download URL requires security-scoped resource access
    /// (i.e., it was created from a user-selected bookmark)
    static var downloadURLRequiresSecurityScope: Bool {
        return UserDefaults.standard.data(forKey: Prefs.key(.downloadPathBookmark)) != nil
    }

    /// Safely starts accessing the security-scoped resource for the download URL
    /// Returns true if access was started, false otherwise
    /// Only call this if the URL requires security-scoped access
    @discardableResult
    static func startAccessingDownloadURL() -> Bool {
        guard downloadURLRequiresSecurityScope else {
            // Default Downloads folder doesn't need security-scoped access
            return false
        }
        return downloadURL.startAccessingSecurityScopedResource()
    }

    /// Safely stops accessing the security-scoped resource for the download URL
    /// Only call this if startAccessingDownloadURL() returned true
    static func stopAccessingDownloadURL(_ started: Bool) {
        if started {
            downloadURL.stopAccessingSecurityScopedResource()
        }
    }

    static func saveDownloadURL(_ url: URL) {
        // Save the path
        UserDefaults.standard.set(url.path, forKey: Prefs.key(.downloadPath))

        // Create and save security-scoped bookmark for custom folders
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: Prefs.key(.downloadPathBookmark))
            print("Security-scoped bookmark saved for: \(url.path)")
        } catch {
            print("Error creating bookmark: \(error.localizedDescription)")
        }

        // Post notification for UI refresh
        NotificationCenter.default.post(name: .downloadPathChanged, object: nil)
    }

    static var languageSelectionShown: Bool {
        return UserDefaults.standard.bool(forKey: Prefs.key(.languageSelectionShown))
    }

    // Save user preferences (LanguageSelectionShown)
    static func setLanguageSelectionShown() {
        UserDefaults.standard.set(true, forKey: Prefs.key(.languageSelectionShown))
    }

    static func resetLanguageSelectionShown() {
        UserDefaults.standard.set(false, forKey: Prefs.key(.languageSelectionShown))
    }

    static let byteFormatter = ByteCountFormatter()
}

extension Notification.Name {
    static let downloadPathChanged = Notification.Name("DownloadPathChanged")
}
