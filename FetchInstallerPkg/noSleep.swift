//
//  noSleepApp.swift
//  noSleep
//
//  Created by Emilio P Egido on 2025-08-25.
//
// NOT USED
//
// It is a pre-test of a standalone app capable of preventing
// or allowing sleep by pressing a toggle button
// Create a SwiftUI app with a single file, noSleepApp.swift
// It has a Toggle button to enable or disable sleep and a information text

//import SwiftUI
//import IOKit.pwr_mgt
//internal import Combine
//
//class SleepManager: ObservableObject {
//    @Published var preventSleep: Bool = true {
//        didSet {
//            updateSleepAssertion()
//        }
//    }
//    
//    private var assertionID: IOPMAssertionID = 0
//    private let assertionName = "NoSleepApp prevents system sleep" as CFString
//    
//    init() {
//        updateSleepAssertion()
//    }
//    
//    deinit {
//        allowSleep()
//    }
//    
//    private func updateSleepAssertion() {
//        if preventSleep {
//            preventSystemSleep()
//        } else {
//            allowSleep()
//        }
//    }
//    
//    private func preventSystemSleep() {
//        let success = IOPMAssertionCreateWithName(
//            kIOPMAssertionTypeNoDisplaySleep as CFString,
//            IOPMAssertionLevel(kIOPMAssertionLevelOn),
//            assertionName,
//            &assertionID
//        )
//        if success == kIOReturnSuccess {
//            print("Sleep prevented")
//        }
//    }
//    
//    private func allowSleep() {
//        if assertionID != 0 {
//            IOPMAssertionRelease(assertionID)
//            assertionID = 0
//            print("Sleep allowed")
//        }
//    }
//}
//
//struct ContentView: View {
//    @StateObject private var sleepManager = SleepManager()
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            Text(sleepManager.preventSleep ? "System sleep PREVENTED" : "System sleep ALLOWED")
//                .font(.headline)
//                .foregroundColor(sleepManager.preventSleep ? .red : .green)
//            
//            Toggle(isOn: $sleepManager.preventSleep) {
//                Text("Prevent System Sleep")
//            }
//            .toggleStyle(SwitchToggleStyle())
//            .padding()
//            Spacer()
//        }
//        .frame(width: 280, height: 120)
//    }
//}
//
//@main
//struct NoSleepApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .frame(width: 440, height: 304)
//        }
//    }
//}

