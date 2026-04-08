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
        UserDefaults.standard.set(AppEnvironment.shared.easyScoringMode, forKey: "easyScoringMode")
        
        // Saves changes in the application's managed object context before the application terminates.
        AppEnvironment.shared.coreDataStack.saveMoc()
    }
}
