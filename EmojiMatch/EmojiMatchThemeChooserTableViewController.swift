//
//  EmojiMatchThemeChooserTableViewController.swift
//  EmojiMatch
//
//  Created by Mike Retondo on 1/21/19.
//

import UIKit

class EmojiMatchThemeChooserTableViewController: UITableViewController
{
    // theme, emojis, backgroundColor, faceDownColor, faceUpColor
    let themes = [
        ("Sports",    "🏀🏈⚾️🏊‍♀️🏌️‍♂️🚴‍♀️🏸🏒🏄‍♀️", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ("Animals",   "🐶🐱🦊🐻🐨🐯🐒🐸🐤", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ("Faces",     "😃🤣😍🤢🤪🤓😬🙄😡", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ("Christmas", "🎅🏻🧣🎄❄️⛄️🎁🌨☃️🤶🏻", #colorLiteral(red: 0, green: 0.2784313725, blue: 0.1529411765, alpha: 1), #colorLiteral(red: 0.6043836805, green: 0.0901325949, blue: 0, alpha: 1), #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)),
        ("Halloween", "🦇😱🙀😈🎃👻🍭🍬🍎", #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1), #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)),
        ("Potpourri", "🦕🧵🌴🌭🚀⏰❤️🍿⭐️🥶🎓🕶🤡🐝🦄🍄🌈🌹🌎☔️🍎🍉🍪🥨🍒🎲🎱🥁🛵✈️🏰⛵️💾💡🧲✏️📌💰🔔🇺🇸📫🏆", #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
    ]

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeChooserCell", for: indexPath)

        cell.textLabel?.text = themes[indexPath.row].0
        
        return cell
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
        
        if let indexPath = tableView.indexPathForSelectedRow {
            if let EmojiMatchVC = segue.destination as? EmojiMatchViewController {
                EmojiMatchVC.theme = themes[indexPath.row]
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

}
