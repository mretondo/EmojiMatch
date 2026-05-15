//
//  AppDelegate.sharedAppDelegate.swift
//  EmojiMatch
//

import UIKit
import CoreData

@main
@MainActor
class AppDelegate: UIResponder, UIApplicationDelegate {

    @MainActor
    public static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    static func main() {
        // Your custom app initialization logic here
        UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
    }

    public var highScore: Int64? {
        get { Score.highScore }
        set(newValue) { Score.highScore = newValue }
    }

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Load easyScoringMode from UserDefaults if previously launched
        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        if previouslyLaunched {
            AppEnvironment.shared.easyScoringMode = UserDefaults.standard.bool(forKey: "easyScoringMode")
        } else {
            AppEnvironment.shared.easyScoringMode = false
        }

        return true
	}

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

	func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        UserDefaults.standard.set(AppEnvironment.shared.easyScoringMode, forKey: "easyScoringMode")
    }
}

