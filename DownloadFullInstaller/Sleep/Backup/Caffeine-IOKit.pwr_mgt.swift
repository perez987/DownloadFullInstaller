//
// Caffeine.swift
// Code to prevent sleep while the app is running
//
// Created by Emilio P Egido on 2025-08-25
//

import Foundation
import IOKit.pwr_mgt
import SwiftUI

var assertionID: IOPMAssertionID = 0
var sleepDisabled = false

func disableSystemSleep(reason: String = "Download Full Installer prevents sleep") {
    if !sleepDisabled {
        sleepDisabled = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &assertionID) == kIOReturnSuccess
        let text = "Download Full Installer prevents sleep"
        print(text)
    }
}

func enableSystemSleep() {
    if sleepDisabled {
        IOPMAssertionRelease(assertionID)
        sleepDisabled = false
        let text = "Download Full Installer allows sleep"
        print(text)
    }
}
