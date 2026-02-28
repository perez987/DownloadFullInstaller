//
//  GitHubUpdateChecker.swift
//  Download Full Installer
//
//  Lightweight GitHub Releases update checker (no Sparkle dependency).
//
//  Version routing:
//   - App version starting with "2" → searches all releases for the latest 2.x.x tag.
//   - App version starting with "3" or any other prefix → uses the /releases/latest endpoint.
//

import AppKit
import Foundation

final class GitHubUpdateChecker {

    // MARK: - Singleton

    static let shared = GitHubUpdateChecker()
    private init() {}

    // MARK: - Constants

    private let owner = "perez987"
    private let repo  = "DownloadFullInstaller"

    private var releasesAPIURL: String {
        "https://api.github.com/repos/\(owner)/\(repo)/releases"
    }

    private var latestReleaseAPIURL: String {
        "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
    }

    private var releasesPageURL: String {
        "https://github.com/\(owner)/\(repo)/releases"
    }

    // MARK: - Public API

    /// Checks for updates and shows an alert if a newer version is found (or if the user initiated
    /// the check and is already up to date).
    func checkForUpdates(userInitiated: Bool) {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let majorPrefix = currentVersion.prefix(while: { $0.isNumber })

        if majorPrefix == "2" {
            fetchAllReleasesAndFindLatestWithPrefix("2", currentVersion: currentVersion, userInitiated: userInitiated)
        } else {
            fetchLatestRelease(currentVersion: currentVersion, userInitiated: userInitiated)
        }
    }

    // MARK: - Private helpers

    /// Fetches /releases/latest and compares with the current version.
    private func fetchLatestRelease(currentVersion: String, userInitiated: Bool) {
        guard let url = URL(string: latestReleaseAPIURL) else { return }
        performRequest(url: url, userInitiated: userInitiated) { [weak self] json in
            guard let self else { return }
            guard let tag = json["tag_name"] as? String else {
                if userInitiated { self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: "")) }
                return
            }
            let latestVersion = self.normalizedVersion(tag)
            self.compareAndNotify(latestVersion: latestVersion, currentVersion: currentVersion, userInitiated: userInitiated)
        }
    }

    // Fetches /releases (all releases) and finds the newest one whose tag starts with the given prefix.
    private func fetchAllReleasesAndFindLatestWithPrefix(_ prefix: String, currentVersion: String, userInitiated: Bool) {
        guard let url = URL(string: releasesAPIURL) else { return }
        performRequest(url: url, userInitiated: userInitiated) { [weak self] json in
            guard let self else { return }
            // The releases endpoint returns an array
            guard let releases = json["_array"] as? [[String: Any]] else {
                if userInitiated { self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: "")) }
                return
            }
            // Find the newest non-prerelease tag that starts with the required major prefix
            var bestVersion: String? = nil
            for release in releases {
                guard let tag = release["tag_name"] as? String else { continue }
                let ver = self.normalizedVersion(tag)
                guard ver.hasPrefix(prefix + ".") || ver == prefix else { continue }
                let isDraft = release["draft"] as? Bool ?? false
                let isPrerelease = release["prerelease"] as? Bool ?? false
                guard !isDraft && !isPrerelease else { continue }
                if bestVersion == nil || self.isVersion(ver, newerThan: bestVersion!) {
                    bestVersion = ver
                }
            }
            guard let latestVersion = bestVersion else {
                // No matching release found – silently ignore for automatic checks
                if userInitiated { self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: "")) }
                return
            }
            self.compareAndNotify(latestVersion: latestVersion, currentVersion: currentVersion, userInitiated: userInitiated)
        }
    }

    // Common HTTP GET helper that calls back on the main queue with a parsed JSON dictionary.
    // For the /releases endpoint (array response) the dictionary uses the key "_array".
    private func performRequest(url: URL, userInitiated: Bool, completion: @escaping ([String: Any]) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if error != nil {
                    if userInitiated {
                        self.showErrorAlert(NSLocalizedString("UpdateCheckNetworkError", comment: ""))
                    }
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    if userInitiated {
                        self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
                    }
                    return
                }
                guard let data else {
                    if userInitiated {
                        self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
                    }
                    return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    if let dict = json as? [String: Any] {
                        completion(dict)
                    } else if let array = json as? [[String: Any]] {
                        completion(["_array": array])
                    } else {
                        if userInitiated {
                            self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
                        }
                    }
                } catch {
                    if userInitiated {
                        self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
                    }
                }
            }
        }
        task.resume()
    }

    // MARK: - Version comparison

    // Strips a leading "v" from a tag name (e.g. "v3.0.2" → "3.0.2").
    private func normalizedVersion(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    // Returns true when `newVersion` is strictly newer than `currentVersion` (component-by-component).
    private func isVersion(_ newVersion: String, newerThan currentVersion: String) -> Bool {
        let newParts = newVersion.components(separatedBy: ".").compactMap { Int($0) }
        let curParts = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
        let count = max(newParts.count, curParts.count)
        for i in 0 ..< count {
            let n = i < newParts.count ? newParts[i] : 0
            let c = i < curParts.count ? curParts[i] : 0
            if n > c { return true }
            if n < c { return false }
        }
        return false
    }

    // MARK: - Alert helpers

    private func compareAndNotify(latestVersion: String, currentVersion: String, userInitiated: Bool) {
        if isVersion(latestVersion, newerThan: currentVersion) {
            showUpdateAvailableAlert(latestVersion: latestVersion)
        } else if userInitiated {
            showUpToDateAlert(currentVersion: currentVersion)
        }
    }

    private func showUpdateAvailableAlert(latestVersion: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("UpdateAvailable", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("UpdateAvailableInfo", comment: ""),
            latestVersion
        )
        alert.addButton(withTitle: NSLocalizedString("DownloadUpdate", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("UpdateLater", comment: ""))
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: releasesPageURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func showUpToDateAlert(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("UpToDate", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("UpToDateInfo", comment: ""),
            currentVersion
        )
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
    }

    private func showErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("UpdateCheckError", comment: "")
        alert.informativeText = message
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.runModal()
    }
}
