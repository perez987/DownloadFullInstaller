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
        load()
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
            // Build the installers array without triggering multiple SwiftUI updates
            var newInstallers: [Product] = []

            for (productKey, product) in products {
                product.key = productKey
                if let metainfo = product.extendedMetaInfo {
                    if metainfo.sharedSupport != nil {
                        if !uniqueInstallersList.contains(productKey) {
                            // this is an installer, add to list
                            uniqueInstallersList.append(productKey)
                            newInstallers.append(product)
                        }
                    }
                }
            }

//            print("\(self.thisComponent) : \(products.count) products found")
//            print("\(self.thisComponent) : \(self.installers.count) installer pkgs found")

            // Sort and assign once to minimize SwiftUI updates
            newInstallers.sort { $0.postDate > $1.postDate }
            installers = newInstallers

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
