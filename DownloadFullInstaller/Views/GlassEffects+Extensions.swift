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
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                )
        }
    }

    /// Applies a macOS 26+ glass effect suitable for List rows.
    /// Falls back to a subtle material background with rounded corners on earlier systems.
    @ViewBuilder
    func glassRow(cornerRadius: CGFloat = 8) -> some View {
        if #available(macOS 26.0, *) {
            self
                .listRowBackground(Color.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            padding(8)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                )
                .listRowBackground(Color.clear)
        }
    }

    /// Applies a soft colored background to a List row.
    /// On macOS 26+ uses a glass tint; on earlier systems uses a semi-transparent color fill.
    @ViewBuilder
    func coloredRow(_ color: Color = .blue, opacity: Double = 0.08, cornerRadius: CGFloat = 8) -> some View {
        if #available(macOS 26.0, *) {
            self
                .listRowBackground(Color.clear)
                .glassEffect(.regular.tint(color.opacity(opacity)), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            padding(8)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color.opacity(opacity))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.thinMaterial).opacity(0.7)
                        )
                )
                .listRowBackground(Color.clear)
        }
    }

    /// Applies a subtle macOS 26+ glass effect.
    /// Falls back to a thin material background on earlier systems.
    @ViewBuilder
    func glassSubtle(cornerRadius: CGFloat = 8) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                )
        }
    }
}
