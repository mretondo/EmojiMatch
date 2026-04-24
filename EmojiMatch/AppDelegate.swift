//
//  AppDelegate.sharedAppDelegate.swift
//  EmojiMatch
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    public static var shared: AppDelegate {
        //
        // NOTE: UIApplication.delegate must be used from main thread only
        //
        if Thread.isMainThread {
            return UIApplication.shared.delegate as! AppDelegate
        } else {
            return DispatchQueue.main.sync {
                UIApplication.shared.delegate as! AppDelegate
            }
        }
    }

//    lazy var coreDataStack: CoreDataStack = CoreDataStack(name: "Model")

    static func main() {
        // Your custom app initialization logic here
        UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
    }

    public var highScore: Int64? {
        get { return Score.highScore }
        set(newValue) { Score.highScore = newValue }
    }

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        AppEnvironment.shared.easyScoringMode = false

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
//        self.saveChangesToDisk()
    }

    // MARK: - Core Data stack

//    lazy var persistentContainer: NSPersistentContainer = {
//        /*
//         The persistent container for the application. This implementation
//         creates and returns a container, having loaded the store for the
//         application to it. This property is optional since there are legitimate
//         error conditions that could cause the creation of the store to fail.
//         */
//
//        // Register the transformer at the very beginning.
//        // Transformer for UIColor
//        UIColorValueTransformer.register()
//
//        let container = NSPersistentContainer(name: "Model")
//        container.loadPersistentStores { (storeDescription, error) in
//            // Avoid duplicating objects - There's a constraint on property 'name'
//            // For properties which have been changed in both the external source and in memory, the in memory changes trump the external ones
//            let moc = container.viewContext
//            moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//
//            if let error = error as NSError? {
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Failed to load database: \(error), \(error.userInfo)")
//            }
//        }
//        return container
//    }()

    // MARK: - Core Data Saving support

//    /// Save the changes from the CoreData database held in memory to the on disk database
//    func saveChangesToDisk() {
//        let moc = persistentContainer.viewContext
//
//        guard moc.hasChanges else { return }
//
//        do {
//            try moc.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nserror = error as NSError
//            fatalError("Unresolved CoreData error \(nserror), \(nserror.userInfo)")
//        }
//    }
}

