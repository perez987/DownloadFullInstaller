//
//  Prefs.swift
//
//  Created by Armin Briegel on 2021-06-15
//

import Foundation

struct Prefs {
    enum Key: String {
        case seedProgram = "SeedProgram"
        case osNameID = "OsNameID"
        case downloadPath = "DownloadPath"
        case languageSelectionShown = "LanguageSelectionShown"
    }

    static func key(_ key: Key) -> String {
        return key.rawValue
    }

    // Save user preferences (AppleLanguages and LanguageSelectionShown)
    static func registerDefaults() {
        var prefs = [String: Any]()
        prefs[Prefs.key(.seedProgram)] = SeedProgram.noSeed.rawValue
        prefs[Prefs.key(.osNameID)] = OsNameID.osAll.rawValue
        prefs[Prefs.key(.languageSelectionShown)] = false

        guard let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        prefs[Prefs.key(.downloadPath)] = downloadURL.path
//        print("Download path: \(downloadURL.path)")

        UserDefaults.standard.register(defaults: prefs)
    }

    // Delete preferences plist file, the app will run as if it were the first time
    static func delPlist(){
            let fileManager = FileManager.default
            let directory = URL.libraryDirectory.appending(path: "Preferences").path()
            let documentURL = directory + "/perez987.DownloadFullInstaller.plist"
//            print("Preferences plist file: \(documentURL)")
            do {
               try fileManager.removeItem(atPath: documentURL)
               print("Preferences plist file deleted sucessfully")
            } catch {
               print("Error deleting Preferences plist file: \(error)")
            }
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
    
    static var languageSelectionShown: Bool {
        return UserDefaults.standard.bool(forKey: Prefs.key(.languageSelectionShown))
    }

    // Save user preferences (LanguageSelectionShown)
    static func setLanguageSelectionShown() {
        UserDefaults.standard.set(true, forKey: Prefs.key(.languageSelectionShown))
    }
    
    static func resetLanguageSelectionShown() {
        UserDefaults.standard.set(false, forKey: Prefs.key(.languageSelectionShown))
    }

    static let byteFormatter = ByteCountFormatter()
}
