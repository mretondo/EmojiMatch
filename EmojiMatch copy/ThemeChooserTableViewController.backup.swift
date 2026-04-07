//
//  ThemeChooserTableViewController.swift
//  EmojiMatch
//
//  Created by Mike Retondo on 1/21/19.
//

import UIKit
import CoreData

class ThemeChooserTableViewController: UITableViewController
{
    typealias DiffableDataSource = EditEnabledDiffableDataSource
    typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Sections, NSManagedObjectID>

    // MARK: - Properties
    enum Sections: CaseIterable {
        case first
    }

//    lazy var coreDataStack = CoreDataStack(name: "Model")
    var dataSource: DiffableDataSource?

    lazy var fetchedResultsController: NSFetchedResultsController<Theme> = {
        let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
        let nameDescriptor = NSSortDescriptor(SortDescriptor(\Theme.name, comparator: .localizedStandard))

        fetchRequest.sortDescriptors = [nameDescriptor]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: AppEnvironment.shared.coreDataStack.moc,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)

        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    // cache for the random emojis to be shown while the view
    // table is shown, resets after restart of game
    var emojiImageViewCache: [String : String] = [:]

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        AppEnvironment.shared.themeChooserTableViewController = self

        // need to call tableView.register() if NOT using Storyboard else
        // in the Identity Inspector set Custom Class to your Custom Cell Classname
        // tableView.register(CustomThemeChooserCell.self, forCellReuseIdentifier: CustomThemeChooserCell.cellIdentifier)
        // tableView.register(CustomThemeChooserCell.self, forHeaderFooterViewReuseIdentifier: CustomThemeChooserCell.cellIdentifier)

        dataSource = setupDataSource()
        dataSource?.defaultRowAnimation = .left // makes all the deletions look better BUT IT'S NOT WORKING

        // now loaded from CoreDataStack.seedCoreDataContainerIfFirstLaunch()
//        loadDefaultThemes()

        printThemesTableStats()
    }

    override func viewDidAppear( _ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.performWithoutAnimation {
            do {
                try fetchedResultsController.performFetch()
                
                // Update the diffable data source with the fetched results
                var snapshot = DiffableDataSourceSnapshot()
                snapshot.appendSections([.first])
                let objectIDs = fetchedResultsController.fetchedObjects?.map { $0.objectID } ?? []
                snapshot.appendItems(objectIDs, toSection: .first)
                dataSource?.apply(snapshot, animatingDifferences: false)
            } catch let error as NSError {
                print("viewDidAppear() - Fetching error: \(error), \(error.userInfo)")
            }
        }
    }

    /// Load the default Themes moc into CoreData and display them
    private func loadDefaultThemes() {
        let coreDataStack = AppEnvironment.shared.coreDataStack

        for themeItem in Theme.defaultThemes {
            _ = coreDataStack.insertTheme(from: themeItem)
        }

        coreDataStack.saveMoc()
    }

    func insertTheme(from themeItem: ThemeItem) {
        let coreDataStack = AppEnvironment.shared.coreDataStack

        let managedObjectID = coreDataStack.insertTheme(from: themeItem)

        let newTheme = Theme(context: coreDataStack.moc)
        let objectID = newTheme.objectID // The type of objectID is NSManagedObjectID

        newTheme.backgroundColor  = themeItem.backgroundColor
        newTheme.emojis           = themeItem.emojis
        newTheme.faceDownColor    = themeItem.faceDownColor
        newTheme.faceUpColor      = themeItem.faceUpColor
        newTheme.name             = themeItem.name

        coreDataStack.saveMoc()
    }

    func printThemesTableStats() {
#if DEBUG
        print ("\nBundle.main Dir: \(Bundle.main.resourcePath!)\n")

        whereIsCoreDataFileDirectory()

        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        let moc = AppEnvironment.shared.coreDataStack.moc
        Task {
            do {
                // no data is retrieved, the database only retrieves the record count
                let count = try await moc.perform {
                    try moc.count(for: Theme.fetchRequest())
                }
                print ("\n\(count) Themes in database\n")
            } catch {
                print ("\nNo Themes in database\n")
            }
        }
#endif
    }

    func whereIsCoreDataFileDirectory() {
        let path = NSPersistentContainer
            .defaultDirectoryURL()
            .absoluteString
            .replacing("file://", with: "Core Data Dir: ")

        print(path + "\n")
    }

    // pick emoji to display before table item label
    private func emojiImageForTheme(_ theme: Theme) -> UIImage? {
        // pick emoji to display before theme Name text
        // each time the table view is displayed a new set of random emojis will be choosen
        let name = theme.name!

        var emoji = emojiImageViewCache[name]
        if emoji == nil {
            // add emoji to cache
            emoji = pickRandomEmoji(from: theme.emojis!)
            emojiImageViewCache[name] = emoji
        }

        return emoji?.textToImage(withFontSize: 44.0)
    }

    public func pickRandomEmoji(from emojiChoices: String) -> String {
        var emoji = "?"

        if emojiChoices.count > 0 {
            let offset = emojiChoices.count.random
            let index = emojiChoices.index(emojiChoices.startIndex, offsetBy: offset)
            emoji = String(emojiChoices[index...index])
        }

        return emoji
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "Choose Theme" else { return }

        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let cardsViewController = segue.destination as? CardsViewController {
//            cardsViewController.container = container

            if let indexPath = tableView.indexPathForSelectedRow {
                // fetch a theme from the database
                let theme = fetchedResultsController.object(at: indexPath)
                let name = theme.name!
                cardsViewController.theme = (name: name,
                                             emojis: theme.emojis!,
                                             backgroundColor: theme.backgroundColor as! UIColor,
                                             faceDownColor: theme.faceDownColor as! UIColor,
                                             faceUpColor: theme.faceUpColor as! UIColor)
            }
        }
    }

    class EditEnabledDiffableDataSource: UITableViewDiffableDataSource<Sections, NSManagedObjectID> {
//        weak var coreDataStack: CoreDataStack?

        init(coreDataStack: CoreDataStack, tableView: UITableView, cellProvider: @escaping CellProvider) {
//            self.coreDataStack = coreDataStack
            super.init(tableView: tableView, cellProvider: cellProvider)
        }

        // returns false by default if not implemented and UITableViewDiffableDataSource but true if not UITableViewDiffableDataSource (bug?)
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            // if true is returned then UITableViewDelegate's
            // tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) will be called

            // all themes can be deleted
            return true

//            guard let managedObjectID = itemIdentifier(for: indexPath) else {return false}

            // fetch a theme at row index from the database
//            if let theme = try? AppEnvironment.shared.coreDataStack.moc.existingObject(with: managedObjectID) as? Theme {
//                if theme.name == "Christmas" {
//                    return true
//                }
//            }
//
//            return false
        }

        override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return false
        }

//        var deleteClosure: ((NSManagedObjectID) -> Void)?

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            guard editingStyle == .delete else { return }
            guard let managedObjectID = itemIdentifier(for: indexPath) else { return }

            // fetch a theme at row index from the database
            let coreDataStack = AppEnvironment.shared.coreDataStack
            let moc = coreDataStack.moc
            guard let theme = try? moc.existingObject(with: managedObjectID) as? Theme else { return }

            // Delete from Core Data
            moc.delete(theme)

            // Save changes to persistent store
            coreDataStack.saveMoc()
        }
    }
}


// MARK: - Internal
extension ThemeChooserTableViewController {
    func setupDataSource() -> DiffableDataSource {
        DiffableDataSource(coreDataStack: AppEnvironment.shared.coreDataStack, tableView: tableView) { [unowned self] (tableView, indexPath, managedObjectID) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: CustomThemeChooserCell.cellIdentifier, for: indexPath)

            if let cell = cell as? CustomThemeChooserCell {
                if let theme = try? AppEnvironment.shared.coreDataStack.moc.existingObject(with: managedObjectID) as? Theme {
                    cell.text = theme.name!
                    cell.image = emojiImageForTheme(theme)
                }
            }

            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension ThemeChooserTableViewController {
//    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        return UISwipeActionsConfiguration(actions: [makeDeleteContextualAction(forRowAt: indexPath)])
//    }
//
//    private func makeDeleteContextualAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
//        return UIContextualAction(style: .destructive, title: "Delete") { [self] (action, swipeButtonView, completion) in
//            // delete the object
//            let theme = fetchedResultsController.object(at: indexPath)
//            coreDataStack.moc.delete(theme)
//
//            // save the Moc with the deleted object
//            coreDataStack.saveMoc()
//
//            completion(true)
//        }
//    }
//
    // Allows customization of the editingStyle for a particular cell located at 'indexPath'. If not implemented, all editable
    // cells will have UITableViewCellEditingStyleDelete set for them when the table has editing property set to YES.
//    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
//        // Change row number from 100 to row number you want to delete
//        // This is just test code to play with deleting rows e.g. 1 with deleted Christmas row
//        if indexPath.row == 100 {
//            // swipe-to-edit
//            return .delete
//        } else {
//            // prevent swipe-to-edit or insert
//            return .none
//        }
//    }

    // NOTE: this is called AFTER prepare(for:sender:)
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        // If theme.name = Christmas then rename it to Xmas. This will re-sort the tableView so Xmas is at the bottom.
//        // Also the save will add a new item to the database because theme was changed it thinks it's a new item.
//        let theme = fetchedResultsController.object(at: indexPath)
//        guard theme.name != "Christmas" else { return }
//        theme.name = "Xmas"
//
//        // reloadItems() needed to be called before iOS 15 because of a bug in Swift code. This code is no longer needed.
////        if var snapshot = dataSource?.snapshot() {
////            snapshot.reloadItems([theme.objectID])
////            dataSource?.apply(snapshot, animatingDifferences: false)
////        }
//
//        coreDataStack.saveMoc()
//    }

//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
////        let sectionInfo = fetchedResultsController.sections?[section]
////        let titleLabel = UILabel()
////        titleLabel.backgroundColor = .white
////        titleLabel.text = "Themes"//sectionInfo?.name
//
//        let headerView = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 56))
//        let headerCell: CustomThemeChooserCell? = tableView.dequeueReusableCell(withIdentifier: CustomThemeChooserCell.cellIdentifier) as? CustomThemeChooserCell
//        headerCell?.frame = headerView.bounds
//        headerCell?.text = "Themes"//sectionInfo?.name
//        headerView.addSubview(headerCell!)
//        return headerView
//    }
//
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> Double {
//        return 44
//    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ThemeChooserTableViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Build a fresh snapshot from the current FRC data
        var snapshot = DiffableDataSourceSnapshot()

        // Single section only
        snapshot.appendSections([.first])

        let objectIDs = controller.fetchedObjects?.map { ($0 as! NSManagedObject).objectID } ?? []
        snapshot.appendItems(objectIDs, toSection: .first)

        // Apply the snapshot to the main thread
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Custom UITableViewCell
class CustomThemeChooserCell: UITableViewCell {
    static let cellIdentifier = "ThemeChooserCell"

    public var text = "empty"
    public var image: UIImage? = nil

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)

        var contentConfig = defaultContentConfiguration().updated(for: state)

        // increase 'text' default font size
        let fontSize = 44.0
        contentConfig.textProperties.font = contentConfig.textProperties.font.withSize(fontSize)
        contentConfig.text = text

        contentConfig.image = image

        contentConfiguration = contentConfig

//        var backgroundConfig = backgroundConfiguration?.updated(for: state)
//        backgroundConfig?.backgroundColor = .purple
//
//        if state.isHighlighted || state.isSelected {
//            backgroundConfig?.backgroundColor = .orange
//            contentConfig.textProperties.color = .red
//            contentConfig.imageProperties.tintColor = .yellow
//        }

        contentConfiguration = contentConfig
//        backgroundConfiguration = backgroundConfig
    }
}

