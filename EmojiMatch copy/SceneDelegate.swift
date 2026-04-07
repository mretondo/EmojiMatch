//
//  SceneDelegate.swift
//  Match Emojis
//
//  Created by Mike Retondo on 3/1/26.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        AppEnvironment.shared.easyScoringMode = false
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Saves changes in the application's managed object context before the application terminates.
        UserDefaults.standard.set(AppEnvironment.shared.easyScoringMode, forKey: "easyScoringMode")
        AppEnvironment.shared.coreDataStack.saveMoc()
    }
}
