//
//  SUCatalog.swift
//
//  Created by Armin Briegel on 2021-06-09
//

import Combine
import Foundation

@MainActor
class SUCatalog: ObservableObject {
    var thisComponent: String {
        String(describing: self)
    }

    @Published var catalog: Catalog?
    var products: [String: Product]? {
        catalog?.products
    }

    @Published var installers = [Product]()
    var uniqueInstallersList: [String] = []
    private var productSubscriptions = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var hasLoaded = false
    @Published var errorMessage: String?
    private var loadID = UUID()
    private var pendingCatalogs = 0

    init() {
        // Diagnostic logging for sandbox initialization
//        print("=== SUCatalog init() started ===")
        // Don't load() here - it will be called from onAppear in the UI
        // Loading during init happens too early, before sandbox is fully initialized
//        print("SUCatalog initialized without loading data")
//        print("=== SUCatalog init() completed ===")
    }

    func load() {
        let requestID = UUID()
        loadID = requestID
        uniqueInstallersList = []
        productSubscriptions.removeAll()
        // The browser always needs every release, independent of the selected detail.
        let catalogURLArray = catalogURL(for: Prefs.seedProgram, for: .osAll)
        pendingCatalogs = catalogURLArray.count
        isLoading = true
        hasLoaded = false
        errorMessage = nil
        catalog = nil
        installers = []

        for item in catalogURLArray {
            let sessionConfig = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

            let task = session.dataTask(with: item) { [weak self] data, response, error in
                Task { @MainActor [weak self] in
                    guard let self, loadID == requestID else { return }
                    defer {
                        pendingCatalogs -= 1
                        updateLoadingState()
                    }
                    do {
                        if let error { throw error }
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200, let data else {
                            throw URLError(.badServerResponse)
                        }
                        try decode(data: data)
                    } catch {
                        print("SUCatalog: \(error.localizedDescription)")
                        errorMessage = error.localizedDescription
                    }
                }
            }
            task.resume()
        }
    }

    private func decode(data: Data) throws {
        let decoder = PropertyListDecoder()
        catalog = try decoder.decode(Catalog.self, from: data)

        if let products {
            for (productKey, product) in products {
                product.key = productKey
                if let metainfo = product.extendedMetaInfo {
                    if metainfo.sharedSupport != nil {
                        if !uniqueInstallersList.contains(productKey) {
                            // this is an installer, add to list
                            uniqueInstallersList.append(productKey)
                            installers.append(product)
                            observeProductChanges(product)
                            product.loadDistribution()
                        }
                    }
                }
            }

            installers.sort { $0.postDate > $1.postDate }
        }
    }

    private func observeProductChanges(_ product: Product) {
        product.objectWillChange
            .sink { [weak self] _ in
                // Published changes arrive before the product's new values are stored.
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    updateLoadingState()
                    objectWillChange.send()
                }
            }
            .store(in: &productSubscriptions)
    }

    private func updateLoadingState() {
        isLoading = pendingCatalogs > 0 || installers.contains { $0.isLoading }
        hasLoaded = !isLoading
        if let productError = installers.compactMap(\.errorMessage).first {
            errorMessage = productError
        }
    }
}

final class FirmwareProduct: Identifiable {
    let id: String
    let osName: String
    let productVersion: String
    let buildVersion: String
    let size: UInt64
    let url: URL
    let postDate: Date

    var filename: String {
        url.lastPathComponent
    }

    init(osName: String, productVersion: String, buildVersion: String, size: UInt64, url: URL, postDate: Date) {
        id = "\(productVersion)-\(buildVersion)-\(url.absoluteString)"
        self.osName = osName
        self.productVersion = productVersion
        self.buildVersion = buildVersion
        self.size = size
        self.url = url
        self.postDate = postDate
    }
}

@MainActor
final class FirmwareCatalog: ObservableObject {
    private static let firmwaresURL = "https://api.ipsw.me/v2.1/firmwares.json/condensed"
    ///    private static let firmwaresURL = "https://api.ipsw.me/v3/firmwares.json/condensed" // --> to test the message when firmares list is empty
    private let releaseDateFormatter = ISO8601DateFormatter()

    @Published var firmwares = [FirmwareProduct]()
    @Published var isLoading = false
    @Published var hasLoaded = false
    @Published var errorMessage: String?

    func load() {
        guard !isLoading else { return }
        guard let url = URL(string: Self.firmwaresURL) else { return }
        let session = URLSession(configuration: .ephemeral)
        isLoading = true
        hasLoaded = false
        errorMessage = nil

        session.dataTask(with: url) { [weak self] data, response, error in
            if let error {
                print("FirmwareCatalog : \(error.localizedDescription)")
                Task { @MainActor [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = error.localizedDescription
                }
                return
            }

            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200, let data else {
                Task { @MainActor [weak self] in
                    self?.isLoading = false
                    self?.errorMessage = URLError(.badServerResponse).localizedDescription
                }
                return
            }

            Task { @MainActor [weak self] in
                self?.decode(data: data)
            }
        }.resume()
    }

    func filteredFirmwares(for selectedOS: String) -> [FirmwareProduct] {
        if selectedOS == "Legacy" {
            return []
        }

        let selectedVersion = nameOS[selectedOS] ?? "99"
        let selectedMajorVersion = Int(selectedVersion.components(separatedBy: ".").first ?? "")

        return firmwares.filter { firmware in
            let majorVersion = Int(firmware.productVersion.components(separatedBy: ".").first ?? "") ?? 0

            if majorVersion < 11 {
                return false
            }

            guard let selectedMajorVersion, selectedVersion != "99" else {
                return true
            }

            return majorVersion == selectedMajorVersion
        }
    }

    private func decode(data: Data) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(IPSWFirmwaresResponse.self, from: data)
            var uniqueFirmwares = [String: FirmwareProduct]()

            for (identifier, device) in response.devices where identifier.contains("Mac") {
                for firmware in device.firmwares {
                    guard
                        let url = URL(string: firmware.url),
                        firmware.url.lowercased().contains(".ipsw"),
                        let majorVersion = Int(firmware.version.components(separatedBy: ".").first ?? ""),
                        majorVersion >= 11
                    else {
                        continue
                    }

                    let postDate = releaseDateFormatter.date(from: firmware.releasedate ?? "") ?? Date.distantPast
                    let osName = osName(for: majorVersion)
                    let item = FirmwareProduct(
                        osName: osName,
                        productVersion: firmware.version,
                        buildVersion: firmware.buildid,
                        size: firmware.size,
                        url: url,
                        postDate: postDate
                    )

                    let key = "\(firmware.version)-\(firmware.buildid)-\(firmware.url)"
                    uniqueFirmwares[key] = item
                }
            }

            let sortedFirmwares = uniqueFirmwares.values.sorted {
                if $0.postDate == $1.postDate {
                    return $0.productVersion.compare($1.productVersion, options: .numeric) == .orderedDescending
                }
                return $0.postDate > $1.postDate
            }

            firmwares = sortedFirmwares
            isLoading = false
            hasLoaded = true
        } catch {
            print("FirmwareCatalog decode : \(error.localizedDescription)")
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func osName(for majorVersion: Int) -> String {
        switch majorVersion {
        case 27:
            "Golden Gate"
        case 26:
            "Tahoe"
        case 15:
            "Sequoia"
        case 14:
            "Sonoma"
        case 13:
            "Ventura"
        case 12:
            "Monterey"
        case 11:
            "Big Sur"
        default:
            "macOS \(majorVersion)"
        }
    }
}

private struct IPSWFirmwaresResponse: Decodable {
    let devices: [String: IPSWDevice]
}

private struct IPSWDevice: Decodable {
    let firmwares: [IPSWFirmware]
}

private struct IPSWFirmware: Decodable {
    let version: String
    let buildid: String
    let size: UInt64
    let url: String
    let releasedate: String?
}
