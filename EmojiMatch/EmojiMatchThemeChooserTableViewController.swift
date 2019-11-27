//
//  EmojiMatchThemeChooserTableViewController.swift
//  EmojiMatch
//
//  Created by Mike Retondo on 1/21/19.
//

import UIKit
import CoreData

class EmojiMatchThemeChooserTableViewController: FetchedResultsTableViewController
{
    @IBOutlet weak var themeHeading: UINavigationItem!

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

        cell.textLabel?.text = theme.name

        // pick random emoji to display before label
        let emoji = pickRandomEmoji(from: theme.emojis ?? "")
        cell.imageView?.image = emoji.textToImage(ofFontSize: 44.0)

        return cell
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
        var emoji = ""
        
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

        if let EmojiMatchVC = segue.destination as? EmojiMatchViewController {
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            // This will show in the next view controller being pushed
            navigationItem.backBarButtonItem = backItem

            EmojiMatchVC.container = container

            if let indexPath = tableView.indexPathForSelectedRow {
                // fetch a theme from the database
                if let result = fetchedResultsController?.object(at: indexPath) {
                    EmojiMatchVC.theme = (name: result.name!,
                                          emojis: result.emojis!,
                                          backgroundColor: result.backgroundColor as! UIColor,
                                          faceDownColor: result.faceDownColor as! UIColor,
                                          faceUpColor: result.faceUpColor as! UIColor)
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

        var prompt = "Low Score: "
        if let lowestFlips = AppDelegate.lowestFlips {
            prompt.append("\(lowestFlips) Flips")
        }
        themeHeading.prompt = prompt
        
        updateUI()
    }
}

extension String {
    //
    // convert the string to an UIImage
    //
    func textToImage(ofFontSize fontSize: CGFloat) -> UIImage? {
        let nsString = (self as NSString)
        let font = UIFont.systemFont(ofSize: fontSize) // you can change your font size here
        let stringAttributes = [NSAttributedString.Key.font: font]
        
        // calculate size of image
        var imageSize = nsString.size(withAttributes: stringAttributes)
        // raise fractional size values to the nearest higher integer
        imageSize.height = ceil(imageSize.height)
        imageSize.width = ceil(imageSize.width)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        
        // fill image with color, in this case to a transparent background
        UIColor.clear.set()
        UIRectFill(CGRect(origin: CGPoint(), size: imageSize))
        
        // draw text within current graphics context
        nsString.draw(at: CGPoint.zero, withAttributes: stringAttributes)
        
        // create image from context
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
}
