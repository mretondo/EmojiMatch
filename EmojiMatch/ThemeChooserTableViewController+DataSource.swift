//
//  ThemeChooserTableViewController+DataSource.swift
//  Match Emojis
//
//  Created by Mike Retondo on 11/23/19.
//

import UIKit
import CoreData

extension ThemeChooserTableViewController
{
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController?.sections, sections.count > 1 { // no section name otherwise > 0
            return sections[section].name
        } else {
            return nil
        }
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int ) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
}
