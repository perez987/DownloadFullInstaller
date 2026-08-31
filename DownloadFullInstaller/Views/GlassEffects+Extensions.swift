//
//  GlassEffects+Extensions.swift
//
//  Swift 6 / macOS 26 Tahoe glass-style UI helpers
//

import SwiftUI

extension View {
    /// Applies the macOS 26+ glass card effect with a rounded rectangle shape.
    /// Falls back to a subtle material background on earlier systems.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 10) -> some View {
//        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
//        } else {
//            self
//                .background(
//                    RoundedRectangle(cornerRadius: cornerRadius)
//                        .fill(.thinMaterial)
//                )
//        }
    }

    /// Applies a macOS 26+ glass effect suitable for List rows.
    /// Falls back to a subtle material background with rounded corners on earlier systems.
    @ViewBuilder
    func glassRow(cornerRadius: CGFloat = 8) -> some View {
//        if #available(macOS 26.0, *) {
//            self
//                .listRowBackground(Color.clear)
//                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius)
//                )
//        } else {
            self
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
//                        .fill(.quaternary)
                        .fill(.thinMaterial)
                )
                .listRowBackground(Color.clear)
//        }
    }

    /// Applies a subtle macOS 26+ glass effect.
    /// Falls back to a thin material background on earlier systems.
    @ViewBuilder
    func glassSubtle(cornerRadius: CGFloat = 8) -> some View {
//        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
//        } else {
//            self
//                .background(
//                    RoundedRectangle(cornerRadius: cornerRadius)
//                        .fill(.thinMaterial)
//                )
//        }
    }
}
