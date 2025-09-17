//
//  LiquidGlassStyle.swift
//
//  Created for Liquid Glass feature implementation
//  Provides backward-compatible styling with progressive enhancement
//

import SwiftUI

// macOS Version Detection

struct SystemVersion {
    static var current: OperatingSystemVersion {
        ProcessInfo.processInfo.operatingSystemVersion
    }
    
    static var isSequoiaOrLater: Bool {
        if #available(macOS 15.0, *) {
            return true
        }
        return false
    }
    
    static var isTahoeOrLater: Bool {
        if #available(macOS 26.0, *) {
            return true
        }
        return false
    }
}

// Liquid Glass Effects

struct LiquidGlassEffect: ViewModifier {
    let intensity: LiquidGlassIntensity
    
    func body(content: Content) -> some View {
        if SystemVersion.isTahoeOrLater {
            // macOS 26+ (Tahoe): Enhanced liquid glass effects
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        } else if SystemVersion.isSequoiaOrLater {
            // macOS 15+ (Sequoia): Basic liquid glass effects
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.tertiary, lineWidth: 0.3)
                )
        } else {
            // macOS 13-14: No changes to maintain backward compatibility
            content
        }
    }
}

struct LiquidGlassContainer: ViewModifier {
    func body(content: Content) -> some View {
        if SystemVersion.isTahoeOrLater {
            // macOS 26+: Advanced container effects
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        } else if SystemVersion.isSequoiaOrLater {
            // macOS 15+: Basic container effects
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        } else {
            // macOS 13-14: No changes
            content
        }
    }
}

// Intensity Levels

enum LiquidGlassIntensity {
    case subtle
    case medium
    case prominent
}

// View Extensions

extension View {
    func liquidGlass(intensity: LiquidGlassIntensity = .medium) -> some View {
        self.modifier(LiquidGlassEffect(intensity: intensity))
    }
    
    func liquidGlassContainer() -> some View {
        self.modifier(LiquidGlassContainer())
    }
}
