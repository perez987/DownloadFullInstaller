//
//  SUCatalog.swift
//
//  Created by Armin Briegel on 2021-06-09
//  Modified by Emilio P Egido on 2025-12-8
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
    
    private var pendingCatalogCount = 0
    private var accumulatedInstallers: [Product] = []
    private var isLoadInProgress = false

    init() {
        load()
    }

    func load() {
        // Prevent concurrent load operations
        guard !isLoadInProgress else { return }
        isLoadInProgress = true
        
        uniqueInstallersList = []
        accumulatedInstallers = []
        let catalogURLArray: [URL] = catalogURL(for: Prefs.seedProgram, for: Prefs.osNameID)
        
        // Track how many catalogs we're loading
        pendingCatalogCount = catalogURLArray.count
        
        // Set initial state once before starting all loads
        isLoading = true
        hasLoaded = false
        catalog = nil
        installers = [Product]()

        for item in catalogURLArray {
            let sessionConfig = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

            let task = session.dataTask(with: item) { data, response, error in
                if error != nil {
                    print("\(self.thisComponent) : \(error!.localizedDescription)")
                    DispatchQueue.main.async {
                        self.finalizeCatalogLoad()
                    }
                    return
                }

                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
//                    print("\(self.thisComponent) : \(httpResponse.statusCode)")
                    DispatchQueue.main.async {
                        self.finalizeCatalogLoad()
                    }
                } else {
                    if data != nil {
//                        print("\(self.thisComponent) : \(String(decoding: data!, as: UTF8.self))")
                        DispatchQueue.main.async {
                            self.decode(data: data!)
                        }
                    }
                }
            }
            task.resume()
        }
    }

    private func decode(data: Data) {
        let decoder = PropertyListDecoder()
        
        // Use proper error handling instead of force unwrap
        do {
            catalog = try decoder.decode(Catalog.self, from: data)
        } catch {
            print("\(self.thisComponent) : Failed to decode catalog: \(error.localizedDescription)")
            finalizeCatalogLoad()
            return
        }

        if let products = products {
            // Accumulate products without triggering SwiftUI updates
            for (productKey, product) in products {
                product.key = productKey
                if let metainfo = product.extendedMetaInfo {
                    if metainfo.sharedSupport != nil {
                        if !uniqueInstallersList.contains(productKey) {
                            // this is an installer, add to accumulated list
                            uniqueInstallersList.append(productKey)
                            accumulatedInstallers.append(product)
                        }
                    }
                }
            }

            print("\(self.thisComponent) : \(accumulatedInstallers.count) total number of installer found")
//            print("\(self.thisComponent) : \(pendingCatalogCount) catalog/s found")
            
        }
        
        // Mark this catalog as processed
        finalizeCatalogLoad()
    }
    
    private func finalizeCatalogLoad() {
        pendingCatalogCount -= 1
        
        // Only update the installers array once all catalogs are loaded
        if pendingCatalogCount == 0 {
            isLoading = false
            hasLoaded = true
            isLoadInProgress = false
            
//            print("\(self.thisComponent) : \(self.accumulatedInstallers.count) installer pkgs found")
            
            // Sort and assign once to minimize SwiftUI updates
            accumulatedInstallers.sort { $0.postDate > $1.postDate }
            installers = accumulatedInstallers

            // Defer loadDistribution() calls to avoid reentrant NSTableView operations
            // Use asyncAfter to ensure the List view completes its initial rendering
            // before the @Published properties in Product are updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for product in self.installers {
                    product.loadDistribution()
                }
            }
        }
    }
}
