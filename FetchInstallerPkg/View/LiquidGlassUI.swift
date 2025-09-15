//
//  LiquidGlassUI.swift
//  FetchInstallerPkg
//
//  Created for Liquid Glass UI support in macOS Tahoe
//  Created on 2025-01-27
//

import SwiftUI

/// Liquid Glass UI styling system for macOS Sequoia (15.0+) and Tahoe (26.0+)
/// Provides enhanced translucent visual effects while maintaining backward compatibility
@available(macOS 10.14, *)
struct LiquidGlassUI {
    
    // MARK: - Availability Checks
    
    /// Check if enhanced liquid glass effects are available (macOS 15.0+)
    static var isLiquidGlassAvailable: Bool {
        if #available(macOS 15.0, *) {
            return true
        }
        return false
    }
    
    /// Check if advanced Tahoe features are available (macOS 26.0+)
    static var isAdvancedTahoeAvailable: Bool {
        if #available(macOS 26.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - Material Styles
    
    /// Primary background material for main content areas
    static var primaryBackground: some View {
        Group {
            if #available(macOS 15.0, *) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .opacity(0.8)
            } else {
                Color(NSColor.controlBackgroundColor)
            }
        }
    }
    
    /// Secondary background material for cards and panels
    static var secondaryBackground: some View {
        Group {
            if #available(macOS 15.0, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
                    .opacity(0.6)
            } else {
                Color(NSColor.windowBackgroundColor)
            }
        }
    }
    
    /// Interactive element background
    static var interactiveBackground: some View {
        Group {
            if #available(macOS 15.0, *) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            } else {
                Color.clear
            }
        }
    }
    
    // MARK: - Text Styles
    
    /// Primary text color with liquid glass opacity
    static var primaryText: some ShapeStyle {
        Group {
            if #available(macOS 15.0, *) {
                .primary.opacity(0.9)
            } else {
                .primary
            }
        }
    }
    
    /// Secondary text color with enhanced transparency
    static var secondaryText: some ShapeStyle {
        Group {
            if #available(macOS 15.0, *) {
                .secondary.opacity(0.8)
            } else {
                .secondary
            }
        }
    }
    
    /// Accent text color for interactive elements
    static var accentText: some ShapeStyle {
        Group {
            if #available(macOS 15.0, *) {
                .tint.opacity(0.9)
            } else {
                .tint
            }
        }
    }
    
    // MARK: - View Modifiers
    
    /// Apply liquid glass styling to any view
    static func liquidGlassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            if #available(macOS 15.0, *) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .opacity(0.7)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
            
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }
    
    /// Apply liquid glass button styling
    static func liquidGlassButton<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            if #available(macOS 15.0, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
                    .opacity(0.6)
            }
            
            content()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
    }
    
    /// Enhanced circular button for liquid glass UI
    static func liquidGlassCircularButton<Content: View>(size: CGFloat = 32, @ViewBuilder content: () -> Content) -> some View {
        ZStack {
            if #available(macOS 15.0, *) {
                Circle()
                    .fill(.thinMaterial)
                    .opacity(0.6)
                    .frame(width: size, height: size)
            }
            
            content()
        }
    }
}

// MARK: - View Extensions

@available(macOS 10.14, *)
extension View {
    
    /// Apply liquid glass card styling to any view
    func liquidGlassCard() -> some View {
        LiquidGlassUI.liquidGlassCard {
            self
        }
    }
    
    /// Apply liquid glass button styling to any view
    func liquidGlassButton() -> some View {
        LiquidGlassUI.liquidGlassButton {
            self
        }
    }
    
    /// Apply liquid glass text styling
    func liquidGlassText(style: LiquidGlassTextStyle = .primary) -> some View {
        self.foregroundStyle(
            Group {
                switch style {
                case .primary:
                    LiquidGlassUI.primaryText
                case .secondary:
                    LiquidGlassUI.secondaryText
                case .accent:
                    LiquidGlassUI.accentText
                }
            }
        )
    }
    
    /// Apply enhanced list row styling for liquid glass
    func liquidGlassListRow() -> some View {
        self.listRowBackground(
            Group {
                if #available(macOS 15.0, *) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)
                } else {
                    Color.clear
                }
            }
        )
    }
}

// MARK: - Supporting Types

enum LiquidGlassTextStyle {
    case primary
    case secondary
    case accent
}

// MARK: - Tahoe-specific Enhancements

@available(macOS 26.0, *)
extension LiquidGlassUI {
    /// Advanced Tahoe-specific liquid glass material
    static var tahoeAdvancedMaterial: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.thickMaterial)
            .opacity(0.9)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.linearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
    }
}