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
    @State private var showRestartAlert = false
    @State private var showSettingsAlert = false

    init(languageManager: LanguageManager, isPresented: Binding<Bool>) {
        self.languageManager = languageManager
        self._isPresented = isPresented
        self._selectedLanguage = State(initialValue: languageManager.currentLanguage)
    }
    
    var body: some View {
        ZStack {
            // Liquid glass background for the entire dialog on macOS 15+
            if #available(macOS 15.0, *) {
                VisualEffectBlur.liquidGlassContent
                    .ignoresSafeArea()
            } else {
                Color(NSColor.windowBackgroundColor)
            }
            
            VStack(spacing: 20) {
                // Header with enhanced styling
                VStack(spacing: 8) {
                    ZStack {
                        if #available(macOS 15.0, *) {
                            Circle()
                                .fill(.thinMaterial)
                                .opacity(0.6)
                                .frame(width: 64, height: 64)
                        }
                        Image(systemName: "globe")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    
                    Text(NSLocalizedString("Language Selection", comment: "Language Selection Dialog title"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            Group {
                                if #available(macOS 15.0, *) {
                                    .primary.opacity(0.9)
                                } else {
                                    .primary
                                }
                            }
                        )
                }
                .padding(.top, 20)
                
                // Language list with enhanced glass effect
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
                .background(
                    Group {
                        if #available(macOS 15.0, *) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial)
                                .opacity(0.8)
                        } else {
                            Color(NSColor.controlBackgroundColor)
                        }
                    }
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            Group {
                                if #available(macOS 15.0, *) {
                                    Color.gray.opacity(0.2)
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }, 
                            lineWidth: 1
                        )
                )
            
                // Buttons with enhanced styling
                HStack(spacing: 12) {
                    Button(NSLocalizedString("Cancel", comment: "")) {
                        isPresented = false
                    }
                    .keyboardShortcut(.escape)
                    .buttonStyle(
                        Group {
                            if #available(macOS 15.0, *) {
                                .bordered
                            } else {
                                .automatic
                            }
                        }
                    )
                    
                    Spacer()
                    
                    Button(NSLocalizedString("Continue", comment: "")) {
                        showRestartAlert = true
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.bordered)
                    .disabled(selectedLanguage == languageManager.currentLanguage)
                .alert(isPresented: $showRestartAlert) {
                    Alert(
                        title: Text(NSLocalizedString("Restart Required", comment: "")),
                        message: Text(NSLocalizedString("The app must be restarted for changes to take effect.", comment: "")),
                        primaryButton: .default(
                            Text(NSLocalizedString("OK", comment: "")),
                            action: {
                                languageManager.setLanguage(selectedLanguage)
                                isPresented = false
                            }
                        ),
                        secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")))
                    )
                    
                }
            }
            
            Divider()

//            .padding(.bottom, 20)
            HStack(spacing: 12) {
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(NSLocalizedString("Clear language settings?", comment: ""))
                    .font(.body)
                
                Button(NSLocalizedString("Yes", comment: "")) {
                    showSettingsAlert = true

                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 10) {
                Text(NSLocalizedString("(Language saved settings will be cleared)", comment: ""))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)

            .alert(isPresented: $showSettingsAlert) {
                Alert(
                    title: Text(NSLocalizedString("Warning", comment: "")),
                    message: Text(NSLocalizedString("You will lose the preferred language you have saved.", comment: "")),
                    primaryButton: .default(
                        Text(NSLocalizedString("OK", comment: "")),
                        action: {
                            UserDefaults.resetDefaults()
                            isPresented = false
                        }
                    ),
                    secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")))
                )

            }

            }
            .padding(.horizontal, 30)
            .frame(width: 400, height: 636)
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
         case "it-IT", "it":
             return "🇮🇹"
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
                
                if isSelected {
                    ZStack {
                        if #available(macOS 15.0, *) {
                            Circle()
                                .fill(.thinMaterial)
                                .opacity(0.6)
                                .frame(width: 24, height: 24)
                        }
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if #available(macOS 15.0, *) {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.thinMaterial)
                                .opacity(0.7)
                        } else {
                            Color.clear
                        }
                    } else {
                        isSelected ? Color.blue.opacity(0.1) : Color.clear
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(
                    Group {
                        if #available(macOS 15.0, *) {
                            Color.gray.opacity(0.1)
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                ),
            alignment: .bottom
        )
    }

}

#Preview {
    
    @State var isPresented = true
    
    let languageManager = LanguageManager()
    
    return LanguageSelectionView(
        languageManager: languageManager,
        isPresented: $isPresented
    )
    
}
