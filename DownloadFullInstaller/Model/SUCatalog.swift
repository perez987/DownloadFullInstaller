//
//  SUCatalog.swift
//
//  Created by Armin Briegel on 2021-06-09
//

import Foundation

class SUCatalog: ObservableObject {
    var thisComponent: String { return String(describing: self) }

    @Published var catalog: Catalog?
    var products: [String: Product]? { return catalog?.products }

    @Published var installers = [Product]()
    var uniqueInstallersList: [String] = []

    @Published var isLoading = false
    @Published var hasLoaded = false

    init() {
        // Diagnostic logging for sandbox initialization
//        print("=== SUCatalog init() started ===")
        // Don't load() here - it will be called from onAppear in the UI
        // Loading during init happens too early, before sandbox is fully initialized
//        print("SUCatalog initialized without loading data")
//        print("=== SUCatalog init() completed ===")
    }

    func load() {
        uniqueInstallersList = []
        let catalogURLArray: [URL] = catalogURL(for: Prefs.seedProgram, for: Prefs.osNameID)

        for item in catalogURLArray {
            let sessionConfig = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

            let task = session.dataTask(with: item) { data, response, error in
                if error != nil {
                    print("\(self.thisComponent) : \(error!.localizedDescription)")
                    return
                }

                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
//                    print("\(self.thisComponent) : \(httpResponse.statusCode)")
                } else {
                    if data != nil {
//                        print("\(self.thisComponent) : \(String(decoding: data!, as: UTF8.self))")
                        DispatchQueue.main.async {
                            self.decode(data: data!)
                        }
                    }
                }
            }
            isLoading = true
            hasLoaded = false
            catalog = nil
            installers = [Product]()
            task.resume()
        }
    }

    private func decode(data: Data) {
        isLoading = false
        hasLoaded = true

        let decoder = PropertyListDecoder()
        catalog = try! decoder.decode(Catalog.self, from: data)

        if let products = products {
            for (productKey, product) in products {
                product.key = productKey
                if let metainfo = product.extendedMetaInfo {
                    if metainfo.sharedSupport != nil {
                        if !uniqueInstallersList.contains(productKey) {
                            // this is an installer, add to list
                            uniqueInstallersList.append(productKey)
                            installers.append(product)
                            product.loadDistribution()
                        }
                    }
                }
            }

            installers.sort { $0.postDate > $1.postDate }
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
        self.id = "\(productVersion)-\(buildVersion)-\(url.absoluteString)"
        self.osName = osName
        self.productVersion = productVersion
        self.buildVersion = buildVersion
        self.size = size
        self.url = url
        self.postDate = postDate
    }
}

final class FirmwareCatalog: ObservableObject {
    private static let firmwaresURL = "https://api.ipsw.me/v3/firmwares.json/condensed"
//    private static let firmwaresURL = "https://api.ipsw.me/v3" // --> to test the message when firmares list is empty
    private let releaseDateFormatter = ISO8601DateFormatter()

    @Published var firmwares = [FirmwareProduct]()
    @Published var isLoading = false
    @Published var hasLoaded = false

    func load() {
        guard let url = URL(string: Self.firmwaresURL) else { return }
        let session = URLSession(configuration: .ephemeral)
        isLoading = true
        hasLoaded = false

        session.dataTask(with: url) { data, _, error in
            if let error {
                print("FirmwareCatalog : \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            self.decode(data: data)
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

            DispatchQueue.main.async {
                self.firmwares = sortedFirmwares
                self.isLoading = false
                self.hasLoaded = true
            }
        } catch {
            print("FirmwareCatalog decode : \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func osName(for majorVersion: Int) -> String {
        switch majorVersion {
        case 26:
            return "Tahoe"
        case 15:
            return "Sequoia"
        case 14:
            return "Sonoma"
        case 13:
            return "Ventura"
        case 12:
            return "Monterey"
        case 11:
            return "Big Sur"
        default:
            return "macOS \(majorVersion)"
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
