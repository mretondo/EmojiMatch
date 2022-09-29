//
//  ThemeChooserTableViewController.swift
//  EmojiMatch
//
//  Created by Mike Retondo on 1/21/19.
//

import UIKit
import CoreData

class ThemeChooserTableViewController: FetchedResultsTableViewController
{
    // cache for the random emojis to be shown while the view
    // table is shown, resets after a selection has been made
    var emojiImageViewCache: [String : String] = [:]

    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet {  }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // need to call tableView.register() if NOT using Storyboard else
        // in the Identity Inspector set Custom Class to your Custom Cell Classname
        //tableView.register(CustomThemeChooserCell.self, forCellReuseIdentifier: CustomThemeChooserCell.identifier)

        setupFetchedResultsController()
        
        setupTableViewDiffableDataSource()

        loadDefaultThemes(Themes.defaultThemes)
    }

    /// Setup the `NSFetchedResultsController`, which manages the data shown in our table view
    private func setupFetchedResultsController() {
        if let moc = container?.viewContext {
            let request = Themes.fetchRequest()
            //            request.fetchBatchSize = 10 // getting data over url

            let sortDescriptors = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
            request.sortDescriptors = [sortDescriptors]

            fetchedResultsController = NSFetchedResultsController<Themes>(fetchRequest: request,
                                                                          managedObjectContext: moc,
                                                                          sectionNameKeyPath: nil,
                                                                          cacheName: nil)
            fetchedResultsController?.delegate = self

            do {
                try fetchedResultsController?.performFetch()
                setupSnapshot()
            } catch {
                fatalError("viewDidLoad - Failed to fetch results from the database")
            }
        }
    }

    /// Setup the `UITableViewDiffableDataSource` with a cell provider that sets up the default table view cell
    private func setupTableViewDiffableDataSource() {
        diffableDataSource = UITableViewDiffableDataSource<Sections, Themes>(tableView: tableView) { (tableView, indexPath, value) -> UITableViewCell? in
            if let cell = tableView.dequeueReusableCell(withIdentifier: CustomThemeChooserCell.cellIdentifier, for: indexPath ) as? CustomThemeChooserCell {
                cell.text = value.name!
                cell.image = self.emojiImageForTheme(value)

                return cell
            } else {
                return UITableViewCell()
            }
        }

        setupSnapshot()
    }

    private func setupSnapshot() {
        var diffableDataSourceSnapshot = NSDiffableDataSourceSnapshot<Sections, Themes>()
        diffableDataSourceSnapshot.appendSections(Sections.allCases)
        diffableDataSourceSnapshot.appendItems(fetchedResultsController?.fetchedObjects ?? [], toSection: .first)
        diffableDataSource?.apply(diffableDataSourceSnapshot) // { impliment closure when the animations are complete }
    }

    /// Load the default Themes moc into CoreData and display them
    private func loadDefaultThemes(_ themes: [Theme]) {
        let moc = AppDelegate.viewContext

        for theme in Themes.defaultThemes {
            let mocThemes = Themes(context: moc)

            mocThemes.backgroundColor  = theme.backgroundColor
            mocThemes.emojis           = theme.emojis
            mocThemes.faceDownColor    = theme.faceDownColor
            mocThemes.faceUpColor      = theme.faceUpColor
            mocThemes.name             = theme.name
        }

        AppDelegate.sharedAppDelegate.saveChangesToDisk()
//        (UIApplication.shared.delegate as? AppDelegate)?.saveChangesToDisk()
        setupSnapshot()
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        setupSnapshot()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    // pick emoji to display before table item label
    private func emojiImageForTheme(_ theme: Themes) -> UIImage? {
        // pick emoji to display before label
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
            cardsViewController.container = container

            if let indexPath = tableView.indexPathForSelectedRow {
                // fetch a theme from the database
                if let result = fetchedResultsController?.object(at: indexPath) {
                    let name = result.name!
                    cardsViewController.theme = (name: name,
                                          emojis: result.emojis!,
                                          backgroundColor: result.backgroundColor as! UIColor,
                                          faceDownColor: result.faceDownColor as! UIColor,
                                          faceUpColor: result.faceUpColor as! UIColor)

                    // show new random set of imojis in the table
                    emojiImageViewCache.removeAll()
                } else {
                    fatalError("prepare(for:sender:) - Attempt to fetched Results based on selected row failed")
                }
            }
        }
    }
}

class CustomThemeChooserCell: UITableViewCell {
    static let cellIdentifier = "ThemeChooserCell"

    public var text = "empty"
    public var image: UIImage? = nil

    // cache for the random emojis to be shown while the view
    // table is shown, resets after a selection has been made
    public var emojiImageViewCache: [String : String] = [:]

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

