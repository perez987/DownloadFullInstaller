//
//  VisualEffectBlur.swift
//  Download Full Installer
//
//  Created by Emilio P Egido on 4/9/25.
//


//
//  VisualEffectBlur.swift
//  MacOS-Calculator
//
//  Created by Oliwer Pawelski on 20/11/2024.
//

// NOT USED

import SwiftUI

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
//        view.material = .contentBackground
        view.material = .headerView // more transparency than contentBackground
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}