//
//  FetchedResultsEmojiMatchThemeChooserTableViewController.swift
//  Match Emojis
//
//  Created by Mike Retondo on 9/7/19.
//

import UIKit
import CoreData

class FetchedResultsEmojiMatchThemeChooserTableViewController: UITableViewController, FetchedResultsTableViewController
{
    var mention: String? { didSet { updateUI() } }
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer { didSet { updateUI() } }
    var fetchedResultsController: NSFetchedResultsController<Themes>?

    private func updateUI() {
        if let context = container?.viewContext {
            let request: NSFetchRequest<Themes> = Themes.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: "handle",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
                )]
            request.predicate = NSPredicate(format: "any themes.text contains[c] %@", mention!)
            fetchedResultsController = NSFetchedResultsController<Themes>(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            fetchedResultsController?.delegate = self
            try? fetchedResultsController?.performFetch()
            tableView.reloadData()
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Themes Cell", for: indexPath)
        if let themes = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = themes.handle
            let themesCount = themesCountWithMentionBy(themes)
            cell.detailTextLabel?.text = "\(themesCount) Themes\((themesCount == 1) ? "" : "s")"
        }
        return cell
    }
    
    private func tweetCountWithMentionBy(_ twitterUser: Score) -> Int {
        let request: NSFetchRequest<Themes> = Themes.fetchRequest()
        request.predicate = NSPredicate(format: "text contains[c] %@ and theme = %@", mention!, themes)
        return (try? themes.managedObjectContext!.count(for: request)) ?? 0
    }
}
