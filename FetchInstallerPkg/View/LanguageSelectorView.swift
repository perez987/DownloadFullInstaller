//
//  LanguageSelectorView.swift
//  FetchInstallerPkg
//
//  Created for language selection with flag icons.
//

import SwiftUI

struct LanguageSelectorView: View {
    @StateObject private var languageManager = LanguageManager()
    @State private var showingLanguageSelector = false
    
    var body: some View {
        HStack {
            Button(action: {
                showingLanguageSelector.toggle()
            }) {
                HStack(spacing: 4) {
                    Text(languageManager.currentLanguage.flagIcon)
                        .font(.system(size: 16))
                    Text(languageManager.currentLanguage.name)
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
                    languageManager: languageManager,
                    isPresented: $showingLanguageSelector
                )
            }
        }
    }
}

struct LanguageSelectionPopover: View {
    @ObservedObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Language")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(Language.allLanguages) { language in
                Button(action: {
                    languageManager.changeLanguage(to: language)
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
                        if language.id == languageManager.currentLanguage.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(language.id == languageManager.currentLanguage.id ? Color.accentColor.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .frame(minWidth: 200)
    }
}

struct LanguageSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectorView()
    }
}