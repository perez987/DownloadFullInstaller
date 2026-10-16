//
//  LanguageSelectionView.swift
//  Created for language selection dialog implementation
//
//  Created by Emilio P Egido on 2025-08-25
//

import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var selectedLanguage: String
    @State private var activeAlert: AppAlertType?

    init(languageManager: LanguageManager, isPresented: Binding<Bool>) {
        self.languageManager = languageManager
        _isPresented = isPresented
        _selectedLanguage = State(initialValue: languageManager.currentLanguage)
    }

    var body: some View {
        ZStack {
            // Frosted glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with globe icon
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.12))
                            .frame(width: 54, height: 54)
                        Image(systemName: "globe")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(.blue)
                    }

                    Text(NSLocalizedString("Language Selection", comment: ""))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding(.top, 28)
                .padding(.bottom, 20)

                // Language list
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(languageManager.availableLanguages, id: \.code) { language in
                            LanguageRow(
                                language: language,
                                isSelected: selectedLanguage == language.code,
                                action: {
                                    selectedLanguage = language.code
                                }
                            )
                        }
                    }
                }
                .frame(height: 300)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 24)

                // Action buttons row
                HStack(spacing: 12) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        isPresented = false
                    }
                    .keyboardShortcut(.escape)

                    Spacer()

                    Button(NSLocalizedString("Continue", comment: "")) {
                        activeAlert = .restartRequired
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedLanguage == languageManager.currentLanguage)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Divider with clear app settings section
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 24)

                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.orange)

                        Text(NSLocalizedString("Clear app settings?", comment: ""))
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Button(NSLocalizedString("Yes", comment: "")) {
                            activeAlert = .warningSettings
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 370, height: 560)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            // Load languages when view appears, ensuring sandbox is fully initialized
            languageManager.loadLanguagesIfNeeded()
            // Update selected language to match current language after loading
            selectedLanguage = languageManager.currentLanguage
        }
        .appAlert(item: $activeAlert) { alertType in
            switch alertType {
            case .restartRequired:
                languageManager.setLanguage(selectedLanguage)
                isPresented = false
            case .warningSettings:
                Prefs.delPlist()
                isPresented = false
            default:
                break
            }
        }
    }
}

struct LanguageRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let action: () -> Void

    private func flagEmoji(for languageCode: String) -> String {
        switch languageCode {
        case "ar":
            "🇸🇦"
        case "en-US", "en":
            "🇺🇸"
        case "es-ES", "es":
            "🇪🇸"
        case "fr-CA":
            "🇨🇦"
        case "fr-FR", "fr":
            "🇫🇷"
        case "it-IT", "it":
            "🇮🇹"
        case "ko-KR", "ko":
            "🇰🇷"
        case "pt-BR":
            "🇧🇷"
        case "ru-RU", "ru":
            "🇷🇺"
        case "sl-SI", "sl":
            "🇸🇮"
        case "uk-UA", "uk":
            "🇺🇦"
        case "zh-Hans", "zh":
            "🇨🇳"
        default:
            "🇺🇸"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(flagEmoji(for: language.code))
                .font(.system(size: 22))
                .frame(width: 30, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(language.nativeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if language.nativeName != language.localizedName {
                    Text(language.localizedName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.system(size: 18))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? Color.blue.opacity(0.12)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
        }
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.primary.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionWrapper()
    }

    struct LanguageSelectionWrapper: View {
        @State private var isPresented = true

        var body: some View {
            LanguageSelectionView(
                languageManager: LanguageManager(),
                isPresented: $isPresented
            )
        }
    }
}
