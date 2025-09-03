//
//  ExtensionScene.swift
//  
//  Created by Emilio P Egido on 2025-09-03.
//


extension Scene {
  func contentSizedWindowResizability() -> some Scene {
    if #available(macOS 13.0, *) {
      return self.windowResizability(.contentSize)
    } else {
      return self
    }
  }
