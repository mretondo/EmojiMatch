import Foundation
import CoreData

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

        // Register the transformers at the very beginning.
        // Transformer for UIColor
        UIColorValueTransformer.register()

        let container = NSPersistentContainer(name: name)
        self.seedCoreDataContainerIfFirstLaunch()
        container.loadPersistentStores { storeDescription, error in
            // Avoid duplicating objects - There's a constraint on property 'name'
            // For properties which have been changed in both the external source and in memory, the in memory changes trump the external ones
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

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
    //swiftlint:disable force_unwrapping
    func seedCoreDataContainerIfFirstLaunch() {
#if DEBUG
        let fileName = Bundle.main.bundleIdentifier!
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let preferences = library.appendingPathComponent("Preferences")
        let userDefaultsPlistURL = preferences.appendingPathComponent(fileName).appendingPathExtension("plist")
//        print("Library directory:", userDefaultsPlistURL.path)
//        print("Preferences directory:", userDefaultsPlistURL.path)
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
            let url = directory.appendingPathComponent(name + ".sqlite")

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
            let shmURL = directory.appendingPathComponent(name + ".sqlite-shm")
            _ = try? FileManager.default.removeItem(at: shmURL)
            do {
                try FileManager.default.copyItem(at: seededSHMURL, to: shmURL)
            } catch let nserror as NSError {
                fatalError("Error: \(nserror.localizedDescription)")
            }

            // Copying the WAL file
            let seededWALURL = Bundle.main.url(forResource: name, withExtension: "sqlite-wal")!
            let walURL = directory.appendingPathComponent(name + ".sqlite-wal")
            _ = try? FileManager.default.removeItem(at: walURL)
            do {
                try FileManager.default.copyItem(at: seededWALURL, to: walURL)
            } catch let nserror as NSError {
                fatalError("Error: \(nserror.localizedDescription)")
            }

            print("Seeded Core Data")
        }
    }
    //swiftlint:enable force_unwrapping
}
