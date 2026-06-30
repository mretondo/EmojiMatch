//
//  EmojiMatchApp.swift
//

import SwiftUI

@main
@MainActor
struct EmojiMatchApp: App {
    var body: some Scene {
        WindowGroup {
            EmojiThemesView()
                .environment(\.managedObjectContext, AppEnvironment.shared.coreDataStack.moc)
                .environment(AppEnvironment.shared)
        }
    }
}
