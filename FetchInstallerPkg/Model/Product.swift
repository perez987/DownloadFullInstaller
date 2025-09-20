//
//  Product.swift
//
//  Created by Armin Briegel on 2021-06-15
//

import Foundation

class Product: Codable, Identifiable, ObservableObject {
    var thisComponent: String { return String(describing: self) }

    let serverMetadataURL: String?
    let packages: [Package]
    let postDate: Date
    let distributions: [String: String]
    let extendedMetaInfo: MetaInfo?

    @Published var sucatalog: SUCatalog?
    @Published var key: String?

    @Published var osName: String?
    @Published var title: String?
    @Published var buildVersion: String?
    var id: String {
        return key ?? "<no id yet>"
    }

    @Published var productVersion: String?
    @Published var installerVersion: String?

    @Published var isLoading = false
    @Published var hasLoaded = false

    var distributionURL: String? {
        if distributions.keys.contains("English") {
            return distributions["English"]!
        } else if distributions.keys.contains("en") {
            return distributions["en"]!
        }
        return nil
    }

    var darwinVersion: String {
        if buildVersion != nil {
            return String(buildVersion!.prefix(2))
        } else {
            return "unknown"
        }
    }

    var buildManifestURL: String? {
        let buildManifest = packages.first { $0.url.hasSuffix("BuildManifest.plist") }
        return buildManifest?.url
    }

    var installerASSPackage: Package? {
        return packages.first { $0.url.hasSuffix("InstallAssistant.pkg") }
    }

    var installerESDPackage: Package? {
        return packages.first { $0.url.hasSuffix("InstallESDDmg.pkg") }
    }

    var installAssistantURL: URL? {
        if let installAssistant = installerASSPackage {
//            print("\(thisComponent) : \(installAssistant)")
            return URL(string: installAssistant.url)
        } else {
            if let installAssistant = installerESDPackage {
//                print("\(thisComponent) : \(installAssistant)")
                return URL(string: installAssistant.url)
            } else {
                return nil
            }
        }
    }

    var installAssistantSize: Int {
        if installerASSPackage != nil {
            return installerASSPackage?.size ?? 0
        } else {
            if installerESDPackage != nil {
                return installerESDPackage?.size ?? 0
            } else {
                return 0
            }
        }
    }

    func loadBuildManifest() {
        guard let urlString = buildManifestURL else { return }
        guard let url = URL(string: urlString) else { return }

        let sessionConfig = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        let task = session.dataTask(with: url) { data, response, error in

            if error != nil {
//                print("\(self.thisComponent) : \(error!.localizedDescription)")
                return
            }

            let httpResponse = response as! HTTPURLResponse
            if httpResponse.statusCode != 200 {
//                print("\(self.thisComponent) : \(httpResponse.statusCode)")
            } else {
                if data != nil {
//                    print("\(self.thisComponent) : \(String(decoding: data!, as: UTF8.self))")
                    DispatchQueue.main.async {
                        self.decodeBuildManifest(data: data!)
                    }
                }
            }
        }

        isLoading = true
        hasLoaded = false
        osName = nil
        title = nil
        buildVersion = nil
        productVersion = nil
        installerVersion = nil
        task.resume()
    }

    func decodeBuildManifest(data: Data) {
        isLoading = false
        hasLoaded = true

        let decoder = PropertyListDecoder()
        if let buildManifest = try? decoder.decode(BuildManifest.self, from: data) {
            buildVersion = buildManifest.productBuildVersion
            productVersion = buildManifest.productVersion
//            print("\(thisComponent) :      Build Version: \(buildVersion ?? "<none>")")
        }
    }

    func loadDistribution() {
        guard let urlString = distributionURL else { return }
        guard let url = URL(string: urlString) else { return }

        let sessionConfig = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        let task = session.dataTask(with: url) { data, response, error in

            if error != nil {
//                print("\(self.thisComponent) : \(error!.localizedDescription)")
                return
            }

            let httpResponse = response as! HTTPURLResponse
            if httpResponse.statusCode != 200 {
//                print("\(self.thisComponent) : \(httpResponse.statusCode)")
            } else {
                if data != nil {
//                    print("\(self.thisComponent) : \(String(decoding: data!, as: UTF8.self))")
                    DispatchQueue.main.async {
                        self.parseDistXML(data: data!)
                    }
                }
            }
        }

        isLoading = true
        hasLoaded = false

        osName = nil
        title = nil
        buildVersion = nil
        productVersion = nil
        installerVersion = nil
        task.resume()
    }

    func parseDistXML(data: Data) {
        let parser = XMLParser(data: data)
        let delegate = DistParserDelegate()
        parser.delegate = delegate
        parser.parse()

        osName = delegate.osName
        title = delegate.title
        productVersion = delegate.productVersion
        buildVersion = delegate.buildVersion
        installerVersion = delegate.installerVersion
        isLoading = false
        hasLoaded = true
    }

    enum CodingKeys: String, CodingKey {
        case serverMetadataURL = "ServerMetadataURL"
        case packages = "Packages"
        case postDate = "PostDate"
        case distributions = "Distributions"
        case extendedMetaInfo = "ExtendedMetaInfo"
    }
}
