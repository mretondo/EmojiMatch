//
//  AppDelegate.swift
//  EmojiMatch
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let defaults = UserDefaults.standard

    static var persistentContainer: NSPersistentContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext // only use on main queue
    }

    public static var lowestFlips: Int? {
        get {
//            return UserDefaults.standard.object(forKey: "lowestFlips") as? Int
            let request: NSFetchRequest<Score> = Score.fetchRequest()
//            request.predicate = NSPredicate(format: "lowestScore = %@", "*")
//            request.sortDescriptors =

            do {
                let lowestScores = try viewContext.fetch(request)
                assert(lowestScores.count <= 1, "lowestFlips - lowestScores count doesn't equal 1")
                if lowestScores.count == 1 {
                    return Int(lowestScores[0].lowestScore)
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        }
        
        set(newValue) {
//            if let lowestFlips = lowestFlips, let newValue = newValue {
//                if newValue < lowestFlips {
//                    UserDefaults.standard.set(newValue, forKey: "lowestFlips")
//                }
//            } else {
//                // save first value
//                UserDefaults.standard.set(newValue, forKey: "lowestFlips")
//            }
            if let newValue = newValue, newValue > -1 {
                let lowestFlipsScore = lowestFlips

                if lowestFlipsScore == nil || newValue < lowestFlipsScore! {
                    // no data is retrieved, the database only retrieves the record count
                    if let count = try? AppDelegate.viewContext.count(for: Score.fetchRequest()), count == 0 {
                        // save first lowest score
                        let score = Score(context: viewContext)
                        score.lowestScore = Int64(newValue)
                    } else {
                        // modify previous saved lowest score
                        let request: NSFetchRequest<Score> = Score.fetchRequest()
                        do {
                            let lowestScores = try? viewContext.fetch(request)
                            let score = lowestScores![0]
                            score.lowestScore = Int64(newValue)
                        }
                    }
                }
            }

            printDatabaseStats()
        }
    }

    public static func printDatabaseStats() {
        #if DEBUG
        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        AppDelegate.viewContext.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? AppDelegate.viewContext.count(for: Score.fetchRequest()) {
                print ("\(count) Score records\n")
            } else {
                print ("No Score records\n")
            }
        }
        #endif
    }
    
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
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
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved CoreData error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved CoreData error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

