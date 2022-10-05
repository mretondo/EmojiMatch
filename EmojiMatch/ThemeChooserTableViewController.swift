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
    typealias DiffableDataSource = UITableViewDiffableDataSource<Sections, NSManagedObjectID>
    typealias DiffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Sections, NSManagedObjectID>

    // MARK: - Properties
    enum Sections: CaseIterable {
        case first
    }

    lazy var  coreDataStack = CoreDataStack(name: "Model")
    var dataSource: DiffableDataSource?

    lazy var fetchedResultsController: NSFetchedResultsController<Theme> = {
        let fetchRequest: NSFetchRequest<Theme> = Theme.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Theme.name), ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))

        fetchRequest.sortDescriptors = [sort]

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: coreDataStack.moc,
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
        //tableView.register(CustomThemeChooserCell.self, forCellReuseIdentifier: CustomThemeChooserCell.cellIdentifier)
        //tableView.register(CustomThemeChooserCell.self, forHeaderFooterViewReuseIdentifier: CustomThemeChooserCell.cellIdentifier)

        dataSource = setupDataSource()

        loadDefaultThemes()

        printThemesTableStats()

    }

    override func viewDidAppear( _ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.performWithoutAnimation {
            do {
                try fetchedResultsController.performFetch()
            } catch let error as NSError {
                print("viewDidLoad() - Fetching error: \(error), \(error.userInfo)")
            }
        }
    }

    /// Load the default Themes moc into CoreData and display them
    private func loadDefaultThemes() {
        let moc = coreDataStack.moc

        for theme in Theme.defaultThemes {
            let newTheme = Theme(context: moc)

            newTheme.backgroundColor  = theme.backgroundColor
            newTheme.emojis           = theme.emojis
            newTheme.faceDownColor    = theme.faceDownColor
            newTheme.faceUpColor      = theme.faceUpColor
            newTheme.name             = theme.name
        }

        coreDataStack.saveMoc()
    }

    func printThemesTableStats() {
#if DEBUG
        whereIsCoreDataFileDirectory()

        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        let moc = coreDataStack.moc
        moc.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? self.coreDataStack.moc.count(for: Theme.fetchRequest()) {
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
                let result = fetchedResultsController.object(at: indexPath)
                let name = result.name!
                cardsViewController.theme = (name: name,
                                             emojis: result.emojis!,
                                             backgroundColor: result.backgroundColor as! UIColor,
                                             faceDownColor: result.faceDownColor as! UIColor,
                                             faceUpColor: result.faceUpColor as! UIColor)
            }
        }
    }
}

// MARK: - Internal
extension ThemeChooserTableViewController {
    func setupDataSource() -> DiffableDataSource {
        DiffableDataSource(tableView: tableView) { tableView, indexPath, managedObjectID -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: CustomThemeChooserCell.cellIdentifier, for: indexPath)

            if let theme = try? self.coreDataStack.moc.existingObject(with: managedObjectID) as? Theme {
                self.configure(cell: cell, for: theme)
            }

            return cell
        }
    }

    func configure(cell: UITableViewCell, for theme: Theme) {
        guard let cell = cell as? CustomThemeChooserCell else { return }

        cell.text = theme.name!
        cell.image = emojiImageForTheme(theme)
    }

//    // TODO: - these two methods need to go int a subclass of UITableViewDiffableDataSource to be called
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        true
//    }
//
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        guard editingStyle == .delete else { return }
//
//        // fetch a theme at row index from the database
//        let theme = fetchedResultsController.object(at: indexPath)
//        coreDataStack.moc.delete(theme)
//
//        if var snapshot = dataSource?.snapshot() {
//            snapshot.deleteItems([theme.objectID])
//            dataSource?.apply(snapshot, animatingDifferences: true)
//        }
//
//        coreDataStack.saveMoc()
//    }
}

// MARK: - UITableViewDelegate
extension ThemeChooserTableViewController {
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let theme = fetchedResultsController.object(at: indexPath)
//        coreDataStack.moc.delete(theme)
//
//        if var snapshot = dataSource?.snapshot() {
//            snapshot.deleteItems([theme.objectID])
//            dataSource?.apply(snapshot, animatingDifferences: true)
//        }
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
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 44
//    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ThemeChooserTableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let snapshot = snapshot as DiffableDataSourceSnapshot
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
        let fontSize = CGFloat(44.0)
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
