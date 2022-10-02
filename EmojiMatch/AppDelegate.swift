//
//  AppDelegate.swift
//  EmojiMatch
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    public static var sharedAppDelegate: AppDelegate {
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

    public static var moc: NSManagedObjectContext {
        return container.viewContext
    }

    public static var container: NSPersistentContainer {
        return sharedAppDelegate.persistentContainer
    }

    public static var highScore: Int64? {
        get { return Score.highScore }
        set(newValue) { Score.highScore = newValue }
    }

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

//        do {
//            try Themes.updateDatabase(with: Themes.defaultThemes)
//        } catch let error as NSError {
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            fatalError("Couldn't update database - CoreData error \(error), \(error.userInfo)")
//        }
//
//        saveChangesToDisk ()
        printThemesTableStats()

        return true
	}

    func printThemesTableStats() {
        #if DEBUG
        whereIsCoreDataFileDirectory()

        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        let moc = persistentContainer.viewContext
        moc.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? AppDelegate.moc.count(for: Theme.fetchRequest()) {
                print ("\(count) Themes in database\n")
            } else {
                print ("No Themes in database\n")
            }
        }
        #endif
    }

    func whereIsCoreDataFileDirectory() {
        let path = NSPersistentContainer
            .defaultDirectoryURL()
            .absoluteString
            .replacingOccurrences(of: "file://", with: "Core Data Dir: ")
            .removingPercentEncoding

        print(path ?? "Not found")
    }

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveChangesToDisk()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */

        // Register the transformer at the very beginning.
        // Transformer for UIColor
        UIColorValueTransformer.register()

        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { (storeDescription, error) in
            // Avoid duplicating objects - There's a constraint on property 'name'
            // For properties which have been changed in both the external source and in memory, the in memory changes trump the external ones
            let moc = container.viewContext
            moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Failed to load database: \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Core Data Saving support

    /// Save the changes from the CoreData database held in memory to the on disk database
    func saveChangesToDisk() {
        let moc = persistentContainer.viewContext

        guard moc.hasChanges else { return }

        do {
            try moc.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved CoreData error \(nserror), \(nserror.userInfo)")
        }
    }
}

