//
//  DistParserDelegate.swift
//
//  Created by Armin Briegel on 2021-06-15
//

import Foundation

#if canImport(FoundationXML)
    import FoundationXML
#endif

class DistParserDelegate: NSObject, XMLParserDelegate {
    enum Elements: String {
        case pkgref = "pkg-ref"
        case auxinfo
        case key
        case string
        case title
    }

    var osName = String()
    var title = String()
    var buildVersion = String()
    var productVersion = String()
    var installerVersion = String()

    private var elementName = String()
    private var parsingAuxinfo = false
    private var currentKey = String()
    private var currentString = String()
    private var keysParsed = 0

    func parserDidEndDocument(_: XMLParser) {
        // Legacy distributions use a localization key instead of a literal title.
        if title == "SU_TITLE" {
            title = nameOS[String(buildVersion.prefix(2))] ?? osName
        }
    }

    func parser(
        _: XMLParser,
        didStartElement elementName: String,
        namespaceURI _: String?,
        qualifiedName _: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == Elements.pkgref.rawValue {
            if attributeDict["id"] == "InstallAssistant"
                || attributeDict["id"] == "InstallESDDmg"
            {
                if let version = attributeDict["version"] {
                    installerVersion = version
                    osName =
                        nameOS[String(installerVersion.prefix(2))] ?? "macOS"
                }
            }
        }

        if elementName == Elements.auxinfo.rawValue {
            parsingAuxinfo = true
        }

        if elementName == Elements.key.rawValue {
            currentKey = String()
        }

        if elementName == Elements.string.rawValue {
            currentString = String()
        }

        self.elementName = elementName
    }

    func parser(
        _: XMLParser,
        didEndElement elementName: String,
        namespaceURI _: String?,
        qualifiedName _: String?
    ) {
        if elementName == Elements.auxinfo.rawValue {
            parsingAuxinfo = false
        }

        if elementName == Elements.key.rawValue {
            keysParsed += 1
        }

        if elementName == Elements.string.rawValue {
            if currentKey == "BUILD" || currentKey == "macOSProductBuildVersion"
            {
                buildVersion = currentString
            } else if currentKey == "VERSION"
                || currentKey == "macOSProductVersion"
            {
                productVersion = currentString
            }
        }
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )

        if !data.isEmpty {
            if elementName == Elements.title.rawValue {
                title += data
            } else if elementName == "key", parsingAuxinfo {
                currentKey += data
            } else if elementName == "string", parsingAuxinfo {
                currentString += data
            }
        }
    }
}
