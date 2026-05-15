//
//  ThemeChooserTableViewController.swift
//  EmojiMatch
//
//  Created by Mike Retondo on 1/21/19.
//

import UIKit
import CoreData

@MainActor
class ThemeChooserTableViewController: UITableViewController
{
    typealias DiffableDataSource = EditEnabledDiffableDataSource
    typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Sections, NSManagedObjectID>

    // MARK: - Properties
    enum Sections: CaseIterable {
        case first
    }

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

        // need to call tableView.register() if NOT using Storyboard else
        // in the Identity Inspector set Custom Class to your Custom Cell Classname
        // tableView.register(CustomThemeChooserCell.self, forCellReuseIdentifier: CustomThemeChooserCell.cellIdentifier)
        // tableView.register(CustomThemeChooserCell.self, forHeaderFooterViewReuseIdentifier: CustomThemeChooserCell.cellIdentifier)

        dataSource = setupDataSource()
        dataSource?.defaultRowAnimation = .left

        // now loaded from CoreDataStack.seedCoreDataContainerIfFirstLaunch()
//        loadDefaultThemes()

        printThemesTableStats()
    }

    override func viewDidAppear( _ animated: Bool) {
        super.viewDidAppear(animated)

        // Only fetch if we haven't already
        if fetchedResultsController.fetchedObjects == nil {
            do {
                try fetchedResultsController.performFetch()
                updateSnapshot(animatingDifferences: false)
            } catch let error as NSError {
                print("viewDidAppear() - Fetching error: \(error), \(error.userInfo)")
            }
        }
    }
    
    private func updateSnapshot(animatingDifferences: Bool) {
        var snapshot = DiffableDataSourceSnapshot()
        snapshot.appendSections([.first])
        let objectIDs = fetchedResultsController.fetchedObjects?.map { $0.objectID } ?? []
        snapshot.appendItems(objectIDs, toSection: .first)
        dataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    /// Load the default Themes moc into CoreData and display them
    private func loadDefaultThemes() {
        let coreDataStack = AppEnvironment.shared.coreDataStack

        for themeItem in Theme.defaultThemes {
            coreDataStack.insertTheme(from: themeItem)
        }
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
        // each time the table view is displayed a new set of random emojis will be chosen
        guard let name = theme.name, let emojis = theme.emojis else {
#if DEBUG
            print("⚠️ emojiImageForTheme: Theme missing name or emojis - \(theme.objectID)")
#endif
            return nil
        }

        var emoji = emojiImageViewCache[name]
        if emoji == nil {
            // add emoji to cache
            emoji = pickRandomEmoji(from: emojis)
            emojiImageViewCache[name] = emoji
        }

        return emoji?.textToImage(withFontSize: 44.0)
    }

    public func pickRandomEmoji(from emojiChoices: String) -> String {
        var emoji = "?"

        if emojiChoices.count > 0 {
            let offset = emojiChoices.count.random
            let index = emojiChoices.index(emojiChoices.startIndex, offsetBy: offset)
            emoji = String(emojiChoices[index])
        }

        return emoji
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "Choose Theme" else { return }

        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let cardsViewController = segue.destination as? CardsViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                // fetch a theme from the database
                let theme = fetchedResultsController.object(at: indexPath)
                
                // Safely unwrap all theme properties
                guard let name = theme.name,
                      let emojis = theme.emojis,
                      let backgroundColor = theme.backgroundColor as? UIColor,
                      let faceDownColor = theme.faceDownColor as? UIColor,
                      let faceUpColor = theme.faceUpColor as? UIColor else {
                    #if DEBUG
                    print("prepare(for:sender:) - Theme has missing or invalid properties")
                    #endif
                    return
                }
                
                cardsViewController.theme = (
                    name: name,
                    emojis: emojis,
                    backgroundColor: backgroundColor,
                    faceDownColor: faceDownColor,
                    faceUpColor: faceUpColor
                )
            }
        }
    }

    class EditEnabledDiffableDataSource: UITableViewDiffableDataSource<Sections, NSManagedObjectID> {
        let onDeleteAtIndexPath: (IndexPath) -> Void

        init(tableView: UITableView, onDeleteAtIndexPath: @escaping (IndexPath) -> Void, cellProvider: @escaping CellProvider) {
            self.onDeleteAtIndexPath = onDeleteAtIndexPath
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

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                self.onDeleteAtIndexPath(indexPath)
            }
        }
    }
}

// MARK: - Internal
extension ThemeChooserTableViewController {
    func setupDataSource() -> DiffableDataSource {
        DiffableDataSource(tableView: tableView, onDeleteAtIndexPath: { [weak self] indexPath in
            guard let self else { return }

            // Validate indexPath against the FRC's current sections and object counts
            guard let sections = self.fetchedResultsController.sections,
                  indexPath.section >= 0, indexPath.section < sections.count else {
                print("Delete skipped: invalid section index \(indexPath.section)")
                return
            }
            let sectionInfo = sections[indexPath.section]
            guard indexPath.row >= 0, indexPath.row < sectionInfo.numberOfObjects else {
                print("Delete skipped: invalid row index \(indexPath.row) in section \(indexPath.section)")
                return
            }

            let moc = AppEnvironment.shared.coreDataStack.moc
            let theme = self.fetchedResultsController.object(at: indexPath)
            moc.delete(theme)
            do {
                try moc.save()
            } catch {
                print("Delete error: \(error)")
            }
        }, cellProvider: { [weak self] (tableView, indexPath, managedObjectID) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: CustomThemeChooserCell.cellIdentifier, for: indexPath)
            if let cell = cell as? CustomThemeChooserCell, let self {
                if let theme = try? AppEnvironment.shared.coreDataStack.moc.existingObject(with: managedObjectID) as? Theme,
                   let name = theme.name {
                    cell.text = name
                    cell.image = self.emojiImageForTheme(theme)
                }
            }
            return cell
        })
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ThemeChooserTableViewController: @preconcurrency NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Update snapshot with animation when content changes
        updateSnapshot(animatingDifferences: true)
    }
}

// MARK: - Custom UITableViewCell
@MainActor
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

