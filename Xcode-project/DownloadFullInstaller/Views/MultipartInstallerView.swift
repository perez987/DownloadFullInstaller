import SwiftUI

/// Compact card for installers delivered as several components, handled as one download.
struct MultipartInstallerView: View {
    @ObservedObject var product: Product
    @ObservedObject private var manager = MultiDownloadManager.shared
    @ObservedObject private var coordinator = MultipartDownloadCoordinator
        .shared
    @ObservedObject private var builder = LegacyInstallerBuildManager.shared
    @State private var activeAlert: AppAlertType?
    @State private var isDownloaded = false

    private var components: [Package] { product.installerComponents }
    private var isComplete: Bool {
        components.count == LegacyInstallerComponents.names.count
    }
    private var totalSize: Int { components.reduce(0) { $0 + $1.size } }
    private var groupTitle: String { product.title ?? product.osName ?? "" }
    private var isDownloading: Bool {
        coordinator.isRunning(id: product.componentFolder)
    }

    private func filename(for package: Package) -> String {
        "\(product.componentFolder)/\(URL(string: package.url)?.lastPathComponent ?? "")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                IconView(product: product)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(groupTitle)
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)
                        Text(product.productVersion ?? "")
                            .font(.title3)
                            .fixedSize()
                        Text(product.buildVersion ?? "")
                            .font(.body)
                            .fixedSize()
                        Spacer(minLength: 4)

                        Button(action: download) {
                            Label(
                                NSLocalizedString(
                                    "Download",
                                    comment: "Download button"
                                ),
                                systemImage: "arrow.down.circle"
                            )
                        }
                        .help(
                            String(
                                format: NSLocalizedString(
                                    "Download %@ %@ (%@) Installer",
                                    comment: ""
                                ),
                                product.osName ?? "",
                                product.productVersion ?? "",
                                product.buildVersion ?? ""
                            )
                        )
                        .disabled(
                            isDownloading || builder.isBuilding || !isComplete
                        )
                        .buttonStyle(.borderedProminent)
                        .opacity(
                            isDownloading || builder.isBuilding || !isComplete
                                ? 0.4 : 1.0
                        )
                    }

                    HStack(spacing: 8) {
                        if isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .help(
                                    NSLocalizedString(
                                        "This installer has been downloaded",
                                        comment: ""
                                    )
                                )
                        }
                        Text(product.postDate, style: .date)
                        Text(
                            Prefs.byteFormatter.string(
                                fromByteCount: Int64(totalSize)
                            )
                        )
                        Spacer()

                        Button {
                            Task { await builder.createInstaller(for: product) }
                        } label: {
                            if builder.isBuilding {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                            } else {
                                Label(
                                    NSLocalizedString(
                                        "Create Installer App",
                                        comment: "Create installer action"
                                    ),
                                    systemImage:
                                        "square.and.arrow.down.on.square"
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            builder.isBuilding || isDownloading || !isDownloaded
                        )
                        .opacity(
                            builder.isBuilding || isDownloading || !isDownloaded
                                ? 0.4 : 1.0
                        )
                    }
                    .font(.body)
                }
            }
            if !isComplete {
                Text(
                    NSLocalizedString(
                        "This catalog does not provide all six required installer components. Try the Regular catalog.",
                        comment: "Incomplete multipart catalog entry"
                    )
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
        .contextMenu {
            Button(NSLocalizedString("Copy Download URL", comment: "")) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    components.map(\.url).joined(separator: "\n"),
                    forType: .string
                )
            }
        }
        .appAlert(item: $activeAlert)
        .onAppear(perform: refreshDownloads)
        .onChange(of: manager.activeDownloadCount) { refreshDownloads() }
        .onChange(of: manager.completedDownloads) { refreshDownloads() }
        .onReceive(
            NotificationCenter.default.publisher(for: .downloadPathChanged)
        ) { _ in refreshDownloads() }
    }

    private func refreshDownloads() {
        let root = Prefs.downloadURL
        let access = Prefs.startAccessingDownloadURL()
        defer { Prefs.stopAccessingDownloadURL(access) }
        isDownloaded =
            isComplete
            && components.allSatisfy { package in
                let path = filename(for: package)
                let values = try? root.appendingPathComponent(path)
                    .resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                return values?.isRegularFile == true
                    && values?.fileSize == package.size
                    && !manager.isDownloading(filename: path)
            }
    }

    private func download() {
        let root = Prefs.downloadURL
        let access = Prefs.startAccessingDownloadURL()
        defer { Prefs.stopAccessingDownloadURL(access) }
        if components.contains(where: {
            FileManager.default.fileExists(
                atPath: root.appendingPathComponent(filename(for: $0)).path
            )
        }) {
            confirmReplace()
        } else {
            startDownload(replacing: false)
        }
    }

    // A modal NSAlert is used because the SwiftUI alert was not presented reliably for this card.
    private func confirmReplace() {
        let alertType = AppAlertType.replaceComponents(
            name: "\(groupTitle) \(product.productVersion ?? "")"
        )
        let alert = NSAlert()
        alert.messageText = alertType.title
        alert.informativeText = alertType.message
        alert.alertStyle = .warning
        alert.addButton(withTitle: alertType.primaryButtonText)
        alert.addButton(withTitle: alertType.dismissButtonText)
        if alert.runModal() == .alertFirstButtonReturn {
            startDownload(replacing: true)
        }
    }

    private func startDownload(replacing: Bool) {
        guard manager.canStartNewDownload else {
            activeAlert = .maxDownloads
            return
        }
        let parts = components.compactMap { package in
            URL(string: package.url).map {
                MultipartDownloadGroup.Component(
                    url: $0,
                    filename: filename(for: package),
                    size: package.size
                )
            }
        }
        do {
            try coordinator.start(
                id: product.componentFolder,
                title: groupTitle,
                components: parts,
                replacing: replacing
            )
            refreshDownloads()
        } catch {
            activeAlert = .downloadError(message: error.localizedDescription)
        }
    }
}
