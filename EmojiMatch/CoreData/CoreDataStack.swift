import Foundation
import CoreData

class CoreDataStack {
    private let name: String

    init(name: String) {
        self.name = name
    }

    lazy var moc: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()

    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */

        // Register the transformers at the very beginning.
        // Transformer for UIColor
        UIColorValueTransformer.register()

        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { (storeDescription, error) in
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

    /// Save the changes from the CoreData database held in memory to the on disk database
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
