//
//  VisualEffectBlur.swift
//  FetchInstallerPkg
//
//  Created by Oliwer Pawelski on 20/11/2024
//  Modified for Liquid Glass UI support on 2025-01-27
//

import SwiftUI

@available(macOS 10.14, *)
struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let isEmphasized: Bool
    
    init(
        material: NSVisualEffectView.Material = .contentBackground,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        isEmphasized: Bool = false
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = isEmphasized
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        
        // Use liquid glass materials for macOS 15+ (Sequoia and Tahoe)
        if #available(macOS 15.0, *) {
            // Enhanced liquid glass materials for Sequoia and Tahoe
            view.material = .fullScreenUI
        } else if #available(macOS 14.0, *) {
            // Use available materials for Sonoma
            view.material = material
        } else {
            // Fallback for older versions
            view.material = .contentBackground
        }
        
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = isEmphasized
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = isEmphasized
    }
}

// Liquid Glass specific variations for different UI contexts
@available(macOS 10.14, *)
extension VisualEffectBlur {
    /// Liquid glass background for main content areas
    static var liquidGlassContent: VisualEffectBlur {
        if #available(macOS 15.0, *) {
            return VisualEffectBlur(
                material: .fullScreenUI,
                blendingMode: .behindWindow,
                isEmphasized: false
            )
        } else {
            return VisualEffectBlur(
                material: .contentBackground,
                blendingMode: .behindWindow,
                isEmphasized: false
            )
        }
    }
    
    /// Liquid glass background for sidebar/menu areas
    static var liquidGlassSidebar: VisualEffectBlur {
        if #available(macOS 15.0, *) {
            return VisualEffectBlur(
                material: .sidebar,
                blendingMode: .behindWindow,
                isEmphasized: true
            )
        } else {
            return VisualEffectBlur(
                material: .sidebar,
                blendingMode: .behindWindow,
                isEmphasized: false
            )
        }
    }
    
    /// Liquid glass background for header areas  
    static var liquidGlassHeader: VisualEffectBlur {
        if #available(macOS 15.0, *) {
            return VisualEffectBlur(
                material: .headerView,
                blendingMode: .behindWindow,
                isEmphasized: true
            )
        } else {
            return VisualEffectBlur(
                material: .headerView,
                blendingMode: .behindWindow,
                isEmphasized: false
            )
        }
    }
}
