//
//  GitHubUpdateChecker.swift
//
//  Lightweight GitHub Releases update checker (no Sparkle dependency).
//

import AppKit
import Foundation

final class GitHubUpdateChecker {
    static let shared = GitHubUpdateChecker()
    private init() {}

    private let owner = "perez987"
    private let repo = "DownloadFullInstaller"

    private var latestReleaseAPIURL: String {
        "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
    }

    private var releasesPageURL: String {
        "https://github.com/\(owner)/\(repo)/releases"
    }

    func checkForUpdates(userInitiated: Bool) {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        fetchLatestRelease(currentVersion: currentVersion, userInitiated: userInitiated)
    }

    private func fetchLatestRelease(currentVersion: String, userInitiated: Bool) {
        guard let url = URL(string: latestReleaseAPIURL) else { return }
        performRequest(url: url, userInitiated: userInitiated) { [weak self] json in
            guard let self else { return }
            guard let tag = json["tag_name"] as? String else {
                if let apiError = json["message"] as? String {
                    print("GitHub updater response error: \(apiError)")
                } else {
                    print("GitHub updater response missing tag_name")
                }
                if userInitiated {
                    self.showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
                }
                return
            }
            let latestVersion = self.normalizedVersion(tag)
            let releasePageURL = json["html_url"] as? String ?? self.releasesPageURL
            self.compareAndNotify(
                latestVersion: latestVersion, currentVersion: currentVersion,
                releasePageURL: releasePageURL, userInitiated: userInitiated
            )
        }
    }

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
                self.parseJSONResponse(data, userInitiated: userInitiated, completion: completion)
            }
        }
        task.resume()
    }

    private func parseJSONResponse(_ data: Data, userInitiated: Bool, completion: ([String: Any]) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            if let dict = json as? [String: Any] {
                completion(dict)
            } else if userInitiated {
                showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
            }
        } catch {
            if userInitiated {
                showErrorAlert(NSLocalizedString("UpdateCheckFailed", comment: ""))
            }
        }
    }

    private func normalizedVersion(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }

    private func isVersion(_ newVersion: String, newerThan currentVersion: String) -> Bool {
        let newParts = newVersion.components(separatedBy: ".").compactMap { Int($0) }
        let curParts = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
        let count = max(newParts.count, curParts.count)
        for idx in 0 ..< count {
            let newPart = idx < newParts.count ? newParts[idx] : 0
            let curPart = idx < curParts.count ? curParts[idx] : 0
            if newPart > curPart { return true }
            if newPart < curPart { return false }
        }
        return false
    }

    private func compareAndNotify(latestVersion: String, currentVersion: String, releasePageURL: String, userInitiated: Bool) {
        if isVersion(latestVersion, newerThan: currentVersion) {
            showUpdateAvailableAlert(latestVersion: latestVersion, releasePageURL: releasePageURL)
        } else if userInitiated {
            showUpToDateAlert(currentVersion: currentVersion)
        }
    }

    private func showUpdateAvailableAlert(latestVersion: String, releasePageURL: String) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("UpdateAvailable", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("UpdateAvailableInfo", comment: ""),
            latestVersion
        )
        alert.addButton(withTitle: NSLocalizedString("DownloadUpdate", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("UpdateLater", comment: ""))
        if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: releasePageURL) {
            NSWorkspace.shared.open(url)
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
