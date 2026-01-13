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
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
//                Image(systemName: "globe")
//                    .font(.system(size: 32))
//                    .foregroundColor(.blue)

                Text(NSLocalizedString("Language Selection", comment: ""))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.top, 20)
//            .frame(
//                minWidth: 400,
//                idealWidth: 400,
//                maxWidth: 400
//            )

            // Language list
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
//                .liquidGlass(intensity: .subtle)
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            // Buttons and alert
            HStack(spacing: 12) {
                Button(NSLocalizedString("Cancel", comment: "")) {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                .liquidGlass(intensity: .subtle)

                Spacer()

                Button(NSLocalizedString("Continue", comment: "")) {
                    activeAlert = .restartRequired
                }
                .keyboardShortcut(.return)
                .buttonStyle(.bordered)
                .disabled(selectedLanguage == languageManager.currentLanguage)
                .liquidGlass(intensity: .subtle)
            }

            Divider()

//            .padding(.bottom, 20)
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text(NSLocalizedString("Clear app settings?", comment: ""))
                    .font(.body)

                Button(NSLocalizedString("Yes", comment: "")) {
                    activeAlert = .warningSettings
                }
                .buttonStyle(.bordered)
                .liquidGlass(intensity: .subtle)
            }

//            HStack(spacing: 10) {
//                Text(NSLocalizedString("(App preferences will be cleared)", comment: ""))
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 30)
        .frame(width: 440, height: 640)
        .background(Color(NSColor.windowBackgroundColor))
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
        case "en-US", "en":
            return "🇺🇸"
        case "es-ES", "es":
            return "🇪🇸"
        case "fr-CA":
            return "🇨🇦"
        case "fr-FR", "fr":
            return "🇫🇷"
        case "ko":
            return "🇰🇷"
        case "it-IT", "it":
            return "🇮🇹"
        case "pt-BR":
            return "🇧🇷"
        case "ru-RU", "ru":
            return "🇷🇺"
        case "uk-UA", "uk":
            return "🇺🇦"
        case "zh-Hans", "zh":
            return "🇨🇳"
        default:
            return "🇺🇸"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(flagEmoji(for: language.code))
                    .font(.title2)
                    .frame(width: 24, height: 24)

                Text(language.nativeName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if language.nativeName != language.localizedName {
                    Text(language.localizedName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
//                    .liquidGlass(intensity: .subtle)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .liquidGlass(intensity: .subtle)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
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
