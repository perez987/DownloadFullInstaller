//
//  Prefs.swift
//  FetchInstallerPkg
//
//  Created by Armin Briegel on 2021-06-15.
//

import Foundation

struct Prefs {
    enum Key: String {
        case seedProgram = "SeedProgram"
        case osNameID = "OsNameID"
        case downloadPath = "DownloadPath"
        case appLanguage = "AppLanguage"
    }

    static func key(_ key: Key) -> String {
        return key.rawValue
    }

    static func registerDefaults() {
        var prefs = [String: Any]()
        prefs[Prefs.key(.seedProgram)] = SeedProgram.noSeed.rawValue
        prefs[Prefs.key(.osNameID)] = OsNameID.osAll.rawValue
        prefs[Prefs.key(.appLanguage)] = "system"

        guard let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        prefs[Prefs.key(.downloadPath)] = downloadURL.path

        UserDefaults.standard.register(defaults: prefs)
    }

    static var seedProgram: SeedProgram {
        let seedValue = UserDefaults.standard.string(forKey: Prefs.key(.seedProgram)) ?? ""
        return SeedProgram(rawValue: seedValue) ?? .noSeed
    }

    static var osNameID: OsNameID {
        let osValue = UserDefaults.standard.string(forKey: Prefs.key(.osNameID)) ?? ""
        return OsNameID(rawValue: osValue) ?? .osAll
    }

    static var downloadPath: String {
        return UserDefaults.standard.string(forKey: Prefs.key(.downloadPath)) ?? ""
    }

    static var downloadURL: URL {
        let downloadURL = URL(fileURLWithPath: downloadPath)
        return downloadURL
    }

    static var appLanguage: String {
        return UserDefaults.standard.string(forKey: Prefs.key(.appLanguage)) ?? "system"
    }

    static let byteFormatter = ByteCountFormatter()
}
