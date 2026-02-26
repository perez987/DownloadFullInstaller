//
//  SUCatalog.swift
//
//  Created by Armin Briegel on 2021-06-09
//

import Foundation
import Combine

class SUCatalog: ObservableObject {
    var thisComponent: String { return String(describing: self) }

    @Published var catalog: Catalog?
    var products: [String: Product]? { return catalog?.products }

    @Published var installers = [Product]()
    var uniqueInstallersList: [String] = []
    private var productCancellables = Set<AnyCancellable>()
    private var sortSubject = PassthroughSubject<Void, Never>()
    private var sortCancellable: AnyCancellable?

    @Published var isLoading = false
    @Published var hasLoaded = false

    init() {
        // Debounce sort triggers so rapid concurrent distribution loads produce one sort
        sortCancellable = sortSubject
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.sortInstallers()
            }
        // Diagnostic logging for sandbox initialization
//        print("=== SUCatalog init() started ===")
        // Don't load() here - it will be called from onAppear in the UI
        // Loading during init happens too early, before sandbox is fully initialized
//        print("SUCatalog initialized without loading data")
//        print("=== SUCatalog init() completed ===")
    }

    func load() {
        uniqueInstallersList = []
        productCancellables.removeAll()
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
                            // Re-sort once this product's distribution data is loaded
                            product.$hasLoaded
                                .filter { $0 }
                                .receive(on: DispatchQueue.main)
                                .sink { [weak self] _ in
                                    self?.sortSubject.send()
                                }
                                .store(in: &productCancellables)
                            product.loadDistribution()
                        }
                    }
                }
            }

            installers.sort { $0.postDate > $1.postDate }
        }
    }

    // Sort installers by postDate descending, then by buildVersion descending as tiebreaker
    private func sortInstallers() {
        installers.sort {
            if $0.postDate != $1.postDate {
                return $0.postDate > $1.postDate
            }
            return compareBuildVersions($0.buildVersion, $1.buildVersion)
        }
    }

    // Compare build version strings semantically (e.g. "24F74" > "23H420")
    // Format: 2-digit Darwin version + letter + number (e.g. "24F74")
    private func compareBuildVersions(_ a: String?, _ b: String?) -> Bool {
        guard let a = a else { return false }
        guard let b = b else { return true }
        guard a.count >= 3, b.count >= 3 else { return a > b }
        let darwinA = Int(a.prefix(2)) ?? 0
        let darwinB = Int(b.prefix(2)) ?? 0
        if darwinA != darwinB { return darwinA > darwinB }
        let restA = String(a.dropFirst(2))
        let restB = String(b.dropFirst(2))
        if restA.prefix(1) != restB.prefix(1) { return restA.prefix(1) > restB.prefix(1) }
        return (Int(restA.dropFirst()) ?? 0) > (Int(restB.dropFirst()) ?? 0)
    }
}
