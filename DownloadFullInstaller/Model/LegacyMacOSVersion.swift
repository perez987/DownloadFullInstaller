//
//  LegacyMacOSVersion.swift
//
//  Created on 2026-01-27
//

import Foundation

// Official Apple download URLs for legacy macOS installers
// These URLs are from Apple's Content Delivery Network (CDN)
// and are the official distribution method for these legacy versions
struct LegacyMacOSVersion: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let url: String

    static let allVersions: [LegacyMacOSVersion] = [
        LegacyMacOSVersion(
            name: "Sierra",
            version: "10.12",
            url: "http://updates-http.cdn-apple.com/2019/cert/061-39476-20191023-48f365f4-0015-4c41-9f44-39d3d2aca067/InstallOS.dmg"
        ),
        LegacyMacOSVersion(
            name: "El Capitan",
            version: "10.11",
            url: "http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg"
        ),
        LegacyMacOSVersion(
            name: "Yosemite",
            version: "10.10",
            url: "http://updates-http.cdn-apple.com/2019/cert/061-41343-20191023-02465f92-3ab5-4c92-bfe2-b725447a070d/InstallMacOSX.dmg"
        ),
        LegacyMacOSVersion(
            name: "Mountain Lion",
            version: "10.8",
            url: "https://updates.cdn-apple.com/2021/macos/031-0627-20210614-90D11F33-1A65-42DD-BBEA-E1D9F43A6B3F/InstallMacOSX.dmg"
        ),
        LegacyMacOSVersion(
            name: "Lion",
            version: "10.7",
            url: "https://updates.cdn-apple.com/2021/macos/041-7683-20210614-E610947E-C7CE-46EB-8860-D26D71F0D3EA/InstallMacOSX.dmg"
        ),
    ]
}
