//
//  Alert+Extensions.swift
//
//  Created for centralized alert management
//  Defines all alert types, titles, messages, and buttons in one place
//

import SwiftUI

// MARK: - AppAlertType

/// Enum defining all alert types used in the application
/// Each case includes properties to get the title, message, and button configuration
enum AppAlertType: Identifiable {
    // InstallerView alerts
    case replaceFile(filename: String)
    case replaceComponents(name: String)
    case maxDownloads
    case installerCreation(title: String, message: String)
    case downloadError(message: String)

    // LanguageSelectionView alerts
    case restartRequired
    case warningSettings

    var id: String {
        switch self {
        case .replaceFile(let filename):
            "replaceFile_\(filename)"
        case .replaceComponents(let name):
            "replaceComponents_\(name)"
        case .maxDownloads:
            "maxDownloads"
        case .installerCreation:
            "installerCreation"
        case .downloadError:
            "downloadError"
        case .restartRequired:
            "restartRequired"
        case .warningSettings:
            "warningSettings"
        }
    }

    /// Returns the localized title for the alert
    var title: String {
        switch self {
        case .replaceFile(let filename):
            String(
                format: NSLocalizedString(
                    "%@ already exists. Do you want to replace it?",
                    comment: ""
                ),
                filename
            )
        case .replaceComponents:
            NSLocalizedString("Download the components again?", comment: "")
        case .maxDownloads:
            NSLocalizedString("Maximum Downloads Reached", comment: "")
        case .installerCreation(let title, _):
            title
        case .downloadError:
            NSLocalizedString("Download Error", comment: "")
        case .restartRequired:
            NSLocalizedString("Restart Required", comment: "")
        case .warningSettings:
            NSLocalizedString("Warning", comment: "")
        }
    }

    /// Returns the localized message for the alert
    var message: String {
        switch self {
        case .replaceFile:
            NSLocalizedString(
                "A file with the same name already exists in that location. Replacing it will overwrite its current contents.",
                comment: ""
            )
        case .replaceComponents(let name):
            String(
                format: NSLocalizedString(
                    "The components of %@ have already been downloaded. Do you want to download them again and replace the existing files?",
                    comment: ""
                ),
                name
            )
        case .maxDownloads:
            NSLocalizedString(
                "You can only run up to 3 downloads at the same time. Please wait for a download to complete before starting a new one.",
                comment: ""
            )
        case .installerCreation(_, let message):
            message
        case .downloadError(let message):
            message
        case .restartRequired:
            NSLocalizedString(
                "The app must be restarted for changes to take effect.",
                comment: ""
            )
        case .warningSettings:
            NSLocalizedString(
                "You will lose user settings and saved language.",
                comment: ""
            )
        }
    }

    /// Returns whether this alert has a primary action (requires two buttons)
    var hasPrimaryAction: Bool {
        switch self {
        case .replaceFile, .replaceComponents, .restartRequired,
            .warningSettings:
            true
        case .maxDownloads, .installerCreation, .downloadError:
            false
        }
    }

    /// Returns the primary button text for alerts with two buttons
    var primaryButtonText: String {
        switch self {
        case .replaceFile, .replaceComponents:
            NSLocalizedString("Replace", comment: "")
        case .restartRequired, .warningSettings:
            NSLocalizedString("OK", comment: "")
        default:
            NSLocalizedString("OK", comment: "")
        }
    }

    /// Returns whether the primary button should be destructive
    var isPrimaryDestructive: Bool {
        switch self {
        case .replaceFile, .replaceComponents:
            true
        default:
            false
        }
    }

    /// Returns the cancel/dismiss button text
    var dismissButtonText: String {
        switch self {
        case .replaceFile, .replaceComponents, .restartRequired,
            .warningSettings:
            NSLocalizedString("Cancel", comment: "")
        case .maxDownloads, .installerCreation, .downloadError:
            NSLocalizedString("OK", comment: "")
        }
    }

    /// Creates an Alert from this alert type
    /// - Parameter primaryAction: Optional action to perform when the primary button is tapped (for alerts with two buttons)
    /// - Returns: A configured Alert
    func createAlert(primaryAction: (() -> Void)? = nil) -> Alert {
        if hasPrimaryAction {
            if isPrimaryDestructive {
                Alert(
                    title: Text(title),
                    message: Text(message),
                    primaryButton: .cancel(Text(dismissButtonText)),
                    secondaryButton: .destructive(
                        Text(primaryButtonText),
                        action: primaryAction ?? {}
                    )
                )
            } else {
                Alert(
                    title: Text(title),
                    message: Text(message),
                    primaryButton: .default(
                        Text(primaryButtonText),
                        action: primaryAction ?? {}
                    ),
                    secondaryButton: .cancel(Text(dismissButtonText))
                )
            }
        } else {
            Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text(dismissButtonText))
            )
        }
    }
}

// MARK: - View Extension for Alert Handling

extension View {
    /// Applies an app-wide alert modifier with type-based action handling
    /// - Parameters:
    ///   - alertType: Binding to the optional AppAlertType to display
    ///   - onAction: Closure that receives the alert type and should return the action to perform
    /// - Returns: Modified view with alert attached
    func appAlert(
        item alertType: Binding<AppAlertType?>,
        onAction: @escaping (AppAlertType) -> Void
    ) -> some View {
        alert(item: alertType) { alert in
            alert.createAlert(primaryAction: { onAction(alert) })
        }
    }

    /// Applies an app-wide alert modifier with a simple primary action
    /// - Parameters:
    ///   - alertType: Binding to the optional AppAlertType to display
    ///   - primaryAction: Optional closure to execute when primary button is tapped
    /// - Returns: Modified view with alert attached
    func appAlert(
        item alertType: Binding<AppAlertType?>,
        primaryAction: (() -> Void)? = nil
    ) -> some View {
        alert(item: alertType) { alert in
            alert.createAlert(primaryAction: primaryAction)
        }
    }
}
