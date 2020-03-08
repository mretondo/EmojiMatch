//
//  AppDelegate.swift
//  EmojiMatch
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // only use on main queue
    public static var viewContext: NSManagedObjectContext {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }

    public static var container: NSPersistentContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    public static var lowestFlips: Int? {
        get { return Score.lowestScore }
        set(newValue) { Score.lowestScore = newValue }
    }

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        #if DEBUG
            // find where database is stored
            let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                            FileManager.SearchPathDomainMask.userDomainMask,
                                                            true)
            print(paths[0])
        #endif

        let themes = [
            // name, emojis, backgroundColor, faceDownColor, faceUpColor
            ("Sports",        "🏀🏈⚾️🏊‍♀️🏌️‍♂️🚴‍♀️🏸🏒🏄‍♀️🎯🎳🏇🏂⛷🏋🏻‍♂️🤸‍♂️⛹️‍♂️🎾🏓⚽️🏏🛹🏹⛸🥌", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Animals",       "🐶🐠🦊🐻🐨🐒🐸🐤🐰🐽🦆🦅🦋🐞🐌🐺🦖🕷🦞🐬🐫🦒🦜🐎🐄", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Faces",         "😃🤣😍🤢🤪🤓😬🙄😡😎🥶🤥😇🤠🤮🙁😤😫🥳😁😮🤐😳😅🥺", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Christmas",     "🎅🏻🧣🎄❄️⛄️🎁🌨☃️🤶🏻🧤", #colorLiteral(red: 0, green: 0.2784313725, blue: 0.1529411765, alpha: 1), #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1), #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)),
            ("Halloween",     "🎃🦇😱🙀😈👻🍭🍬🍎🧛🏻‍♂️🧟‍♂️👺⚰️", #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1), #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)),
            ("Food",          "🍏🍎🍋🍉🍇🍒🥥🥑🥦🌽🥕🥯🥨🥩🍗🌭🍔🍟🍕🌮🍦🧁🍰🎂🍭🍩☕️🍺🧀🍌🌶🍅🥒🍊", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Travel",        "🚗🚌🏎🚑🚒🚜🛴🚲🛵🚔🚠🚃🚂✈️🛩🛰🚀🛸🚁🛶⛵️🛳🚦🗽🗿🏰🏯🎢🏝🌋⛺️🏠🏛🕌⛩", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Flags",          "🏴‍☠️🚩🏳️‍🌈🇺🇸🇨🇦🇫🇷🇨🇳🇷🇺🇮🇳🇮🇱🇯🇵🇮🇹🎌🇲🇾🇲🇽🇳🇵🇳🇴🇵🇦🇨🇭🇬🇧🏁🇮🇪🇲🇾🇻🇳🇧🇩", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Objects",       "⌚️📱💻⌨️🖥🖨🕹🗜📀📸🎥📽🎞📞📺🧭⏰⏳📡🔦🧯🛠🧲🧨💈💊🛎🛏🛒📭📜📆📌🔍🔐🚿🧬📋📎🧷🧮🔬", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
            ("Potpourri",     "🌎🦕🧵🌴🌭🚀⏰❤️🍿⭐️🥶🎓🕶🤡🐝🦄🍄🌈🌹☔️🍎🍉🍪🥨🍒🎲🎱🥁🛵✈️🏰⛵️💾💡🧲✏️📌💰🔔🇺🇸📫🏆", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ]

        // update the database to reflect themes from above
        // might have deleted some and added new ones
        do {
            try Themes.updateDatabase(with: themes, in: persistentContainer.viewContext)
        } catch let error as NSError {
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            fatalError("Couldn't update database - CoreData error \(error), \(error.userInfo)")
        }

        saveContext ()
        printThemesTableStats()

        return true
	}

    func printThemesTableStats() {
        #if DEBUG
        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        persistentContainer.viewContext.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? AppDelegate.viewContext.count(for: Themes.fetchRequest()) {
                print ("\(count) Themes in database\n")
            } else {
                print ("No Themes in database\n")
            }
        }
        #endif
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

