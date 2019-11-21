//
//  EmojiMatchThemeChooserTableViewController.swift
//  EmojiMatch
//
//  Created by Mike Retondo on 1/21/19.
//

import UIKit
import CoreData

class EmojiMatchThemeChooserTableViewController: UITableViewController //FetchedResultsTableViewController
{
    @IBOutlet weak var themeHeading: UINavigationItem!

    //var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = try? AppDelegate.viewContext.count(for: Themes.fetchRequest()) {
            return count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeChooserCell", for: indexPath)

        let contentsOfCells: [(name: String, emojis: String)] = Themes.namesAndEmojis
        if contentsOfCells.count > indexPath.row {
            cell.textLabel?.text = contentsOfCells[indexPath.row].name

            // pick random emoji to display before label
            let emoji = pickRandomEmoji(from: contentsOfCells[indexPath.row].emojis)
            cell.imageView?.image = emoji.textToImage(ofFontSize: 44.0)
        }

        return cell
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
        
        if let indexPath = tableView.indexPathForSelectedRow, let themeName = tableView.cellForRow(at: indexPath)?.textLabel?.text {
            if let theme = Themes.theme(forName: themeName) {
                if let EmojiMatchVC = segue.destination as? EmojiMatchViewController {
                    EmojiMatchVC.theme = theme
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
        
        // force table view to rearange the cell icons
        self.tableView.reloadData()
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
