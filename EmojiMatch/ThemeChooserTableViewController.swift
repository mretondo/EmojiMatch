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
        didSet { updateUI() }
    }

    // MARK: - Table view data source
    var fetchedResultsController: NSFetchedResultsController<Themes>?

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeChooserCell", for: indexPath)

        guard let theme = fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }

        cell.textLabel?.text = theme.name!
        cell.imageView?.image = emojiImageForTheme(theme)

        return cell
    }

    // pick emoji to display before table item label
    private func emojiImageForTheme(_ theme: Themes) -> UIImage? {
        // pick emoji to display before label and cache it
        // each time the table view is displayed a new set of random emojis will be choosen
        let name = theme.name!
        let fontSize = CGFloat(44.0)

        if let emoji = emojiImageViewCache[name] {
            return emoji.textToImage(ofFontSize: fontSize)
        } else {
            let emoji = pickRandomEmoji(from: theme.emojis!)
            emojiImageViewCache[name] = emoji
            return emoji.textToImage(ofFontSize: fontSize)
        }
    }

    private func updateUI() {
        if let context = container?.viewContext {
            let request: NSFetchRequest<Themes> = Themes.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]

            fetchedResultsController = NSFetchedResultsController<Themes>(fetchRequest: request,
                                                                          managedObjectContext: context,
                                                                          sectionNameKeyPath: nil,
                                                                          cacheName: nil)

            fetchedResultsController?.delegate = self
            try? fetchedResultsController?.performFetch()

            // force table view to rearange the cell icons
            tableView.reloadData()
        }
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "Choose Theme" else { return }

        if let EmojiMatchVC = segue.destination as? CardsViewController {
            EmojiMatchVC.container = container

            if let indexPath = tableView.indexPathForSelectedRow {
                // fetch a theme from the database
                if let result = fetchedResultsController?.object(at: indexPath) {
                    let name = result.name!
                    EmojiMatchVC.theme = (name: name,
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
    
    /*
    // MARK: - Navigation
     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateUI()
    }
}

//extension UIView {
//    var heightConstaint: NSLayoutConstraint? {
//        get {
//            return constraints.first(where: {
//                $0.firstAttribute == .height && $0.relation == .equal
//            })
//        }
//        set { setNeedsLayout() }
//    }
//
//    var widthConstaint: NSLayoutConstraint? {
//        get {
//            return constraints.first(where: {
//                $0.firstAttribute == .width && $0.relation == .equal
//            })
//        }
//        set { setNeedsLayout() }
//    }
//}
//
//extension UIView {
//    func copyView<T: UIView>() throws -> T? {
//        let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
//        return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
//    }
//}
