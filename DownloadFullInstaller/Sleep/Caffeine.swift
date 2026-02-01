//
// Caffeine.swift
// Code to prevent sleep while the app is running
//
// Created by Emilio P Egido on 2025-08-25
//

import Foundation
import SwiftUI

var activityToken: NSObjectProtocol?

func disableSystemSleep(reason: String = "DownloadFullInstaller prevents sleep") {
    if activityToken == nil {
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .suddenTerminationDisabled],
            reason: reason
        )
        let text = "Sleep prevented by DownloadFullInstaller"
        print(text)
    }
}

func enableSystemSleep() {
    if let token = activityToken {
        ProcessInfo.processInfo.endActivity(token)
        activityToken = nil
        let text = "Sleep allowed by DownloadFullInstaller"
        print(text)
    }
}
