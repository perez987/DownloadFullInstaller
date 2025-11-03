# Replace #Preview macro with PreviewProvider for macOS 13 compatibility

## Overview

In `LanguageSelectionView.swift` file, line 223, Xcode warns that `@State` inline in `#Preview `requires `@Previewable`, which is macOS 14+ only. Project targets macOS 13.7.

```swift
// Before: #Preview macro with inline @State (warning)
#Preview {
    @State var isPresented = true
    return LanguageSelectionView(...)
}
```

Warning:

`'@State' used inline will not work unless tagged with '@Previewable' (from macro 'Preview')`

## Changes

- Converted `#Preview` macro to `PreviewProvider` protocol
- Wrapped preview in helper view to manage `@State` binding
- Aligns with preview pattern used in other project files (ContentView, PreferencesView, etc.).

```swift
// After: PreviewProvider with wrapper view (no warning)
struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionWrapper()
    }
    
    struct LanguageSelectionWrapper: View {
        @State private var isPresented = true
        var body: some View {
            LanguageSelectionView(...)
        }
    }
}
```

## Summary

This reverts the preview implementation for `LanguageSelectionView` from the modern `#Preview` macro to the traditional `PreviewProvider` protocol, aligning it with the preview pattern used consistently throughout the rest of the codebase.
