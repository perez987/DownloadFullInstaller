//
//  LanguageSelectorView.swift
//  FetchInstallerPkg
//
//  Created for language selection with flag icons.
//

import SwiftUI

struct LanguageSelectorView: View {
    @State private var selectedLanguage: Language = Language.currentLanguage
    @State private var showingLanguageSelector = false
    
    var body: some View {
        HStack {
            Button(action: {
                showingLanguageSelector.toggle()
            }) {
                HStack(spacing: 4) {
                    Text(selectedLanguage.flagIcon)
                        .font(.system(size: 16))
                    Text(selectedLanguage.name)
                        .font(.caption)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showingLanguageSelector, arrowEdge: .bottom) {
                LanguageSelectionPopover(
                    selectedLanguage: $selectedLanguage,
                    isPresented: $showingLanguageSelector
                )
            }
        }
    }
}

struct LanguageSelectionPopover: View {
    @Binding var selectedLanguage: Language
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Language")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Language.allLanguages) { language in
                Button(action: {
                    selectedLanguage = language
                    changeLanguage(to: language.code)
                    isPresented = false
                }) {
                    HStack {
                        Text(language.flagIcon)
                            .font(.system(size: 18))
                        Image(systemName: language.systemIcon)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(language.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if language.id == selectedLanguage.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(language.id == selectedLanguage.id ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .frame(minWidth: 200)
    }
    
    private func changeLanguage(to languageCode: String) {
        // Change the app's language
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Note: In a real app, you might want to restart the app or 
        // implement a more sophisticated language switching mechanism
        print("Language changed to: \(languageCode)")
    }
}

struct LanguageSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectorView()
    }
}