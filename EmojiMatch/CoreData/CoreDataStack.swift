import Foundation
import CoreData
import UIKit

@MainActor
class CoreDataStack {
    // MARK: Properties
    private let name: String

    // MARK: Initializers
    init(name: String) {
        self.name = name
    }

    lazy var moc: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */

        //
        // Register the transformers at the very beginning.
        //
        // Transformer for UIColor
        UIColorValueTransformer.register()

        let container = NSPersistentContainer(name: name)
        self.seedCoreDataContainerIfFirstLaunch()
        container.loadPersistentStores { storeDescription, error in
            // Avoid duplicating objects - There's a constraint on property 'name'
            // For properties which have been changed in both the external source and in memory, the in memory changes trump the external ones
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

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

        // Seed database may contain archived UIColors with component values outside
        // 0–1 (e.g. extended-sRGB P3). NSKeyedUnarchiver creates the UIColor as-is,
        // triggering UIKit's "far outside expected range" warning every session.
        // This one-time migration re-archives each color with clamped components so
        // the stored data is clean on all future launches.
        self.reseedDefaultThemesIfNeeded(in: container.viewContext)

        return container
    }()

    //
    // To insert\add an item into a TableView, you primarily interact with your Core Data NSManagedObjectContext.
    // The NSFetchedResultsController's delegate methods will handle the TableView update automatically.
    //
    func insertTheme(from themeItem: ThemeItem) {
        let newTheme = Theme(context: moc)

        newTheme.name             = themeItem.name
        newTheme.emojis           = themeItem.emojis
        newTheme.backgroundColor  = themeItem.backgroundColor
        newTheme.faceDownColor    = themeItem.faceDownColor
        newTheme.faceUpColor      = themeItem.faceUpColor

        saveMoc()
    }

    /// Save the changes from the CoreData database held in memory to the persistent on disk database
    func saveMoc () {
        guard moc.hasChanges else { return }

        do {
            try moc.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not
            // use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved CoreData error \(nserror), \(nserror.userInfo)")
        }
    }
}

// MARK: Private
private extension CoreDataStack {
    func seedCoreDataContainerIfFirstLaunch() {
#if DEBUG
        let fileName = Bundle.main.bundleIdentifier!
        let preferences = URL.libraryDirectory.appending(path: "Preferences")
        let userDefaultsPlistURL = preferences.appending(path: fileName).appendingPathExtension("plist")
        print("Library directory:", userDefaultsPlistURL.path)
        print("Preferences directory:", userDefaultsPlistURL.path)
        print("UserDefaults plist file:", userDefaultsPlistURL.path)
        if FileManager.default.fileExists(atPath: userDefaultsPlistURL.path) {
            print("UserDefaults plist file found")
        }
#endif

        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        if !previouslyLaunched {
            //
            // copy sqlite template files from Bundle to CoreData directory
            //
            UserDefaults.standard.set(true, forKey: "previouslyLaunched")

            // Default directory where the CoreDataStack will store its files
            let directory = NSPersistentContainer.defaultDirectoryURL()
            let url = directory.appending(path: name + ".sqlite")

            // Copying the SQLite file
            let seededDatabaseURL = Bundle.main.url(forResource: name, withExtension: "sqlite")!
            _ = try? FileManager.default.removeItem(at: url)
            do {
                try FileManager.default.copyItem(at: seededDatabaseURL, to: url)
            } catch let nserror as NSError {
                fatalError("Error: \(nserror.localizedDescription)")
            }

            // Copying the SHM file
            let seededSHMURL = Bundle.main.url(forResource: name, withExtension: "sqlite-shm")!
            let shmURL = directory.appending(path: name + ".sqlite-shm")
            _ = try? FileManager.default.removeItem(at: shmURL)
            do {
                try FileManager.default.copyItem(at: seededSHMURL, to: shmURL)
            } catch let nserror as NSError {
                fatalError("Error: \(nserror.localizedDescription)")
            }

            // Copying the WAL file
            let seededWALURL = Bundle.main.url(forResource: name, withExtension: "sqlite-wal")!
            let walURL = directory.appending(path: name + ".sqlite-wal")
            _ = try? FileManager.default.removeItem(at: walURL)
            do {
                try FileManager.default.copyItem(at: seededWALURL, to: walURL)
            } catch let nserror as NSError {
                fatalError("Error: \(nserror.localizedDescription)")
            }

            print("Seeded Core Data")
        }
    }

    // Runs once. Re-inserts all default themes from the hardcoded Theme.defaultThemes
    // array, replacing the seed-database copies whose archived UIColors may have
    // component values outside 0–1. We delete the old rows without ever reading
    // their UIColor attributes, so NSKeyedUnarchiver is never called on the bad
    // data and the "far outside expected range" warning never fires.
    func reseedDefaultThemesIfNeeded(in context: NSManagedObjectContext) {
        let migrationKey = "colorComponentsMigrationV2"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let defaultNames = Set(Theme.defaultThemes.map { $0.name })
        let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name IN %@", defaultNames)
        guard let existing = try? context.fetch(fetchRequest) else { return }

        existing.forEach { context.delete($0) }

        for item in Theme.defaultThemes {
            let theme = Theme(context: context)
            theme.name            = item.name
            theme.emojis          = item.emojis
            theme.backgroundColor = item.backgroundColor
            theme.faceDownColor   = item.faceDownColor
            theme.faceUpColor     = item.faceUpColor
        }

        if context.hasChanges { try? context.save() }
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
