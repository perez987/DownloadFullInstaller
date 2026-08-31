//
//  MetaInfo.swift
//
//  Created by Armin Briegel on 2021-06-15
//

import Foundation

struct MetaInfo: Codable {
    let installAssistantPackageIdentifiers: [String: String]?

    var installInfo: String? {
        installAssistantPackageIdentifiers?["InstallInfo"]
    }

    var osInstall: String? {
        installAssistantPackageIdentifiers?["OSInstall"]
    }

    var sharedSupport: String? {
        installAssistantPackageIdentifiers?["SharedSupport"]
    }

    var info: String? {
        installAssistantPackageIdentifiers?["Info"]
    }

    var updateBrain: String? {
        installAssistantPackageIdentifiers?["UpdateBrain"]
    }

    var buildManifest: String? {
        installAssistantPackageIdentifiers?["BuildManifest"]
    }

    enum CodingKeys: String, CodingKey {
        case installAssistantPackageIdentifiers = "InstallAssistantPackageIdentifiers"
    }
}
