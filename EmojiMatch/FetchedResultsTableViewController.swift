//
//  FetchedResultsTableViewController.swift
//  Match Emojis
//
//  Created by Mike Retondo on 9/7/19.
//

import UIKit
import CoreData

class FetchedResultsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate
{
    typealias DiffableDataSource = UITableViewDiffableDataSource<Sections, Theme>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Sections, Theme>

    enum Sections: CaseIterable {
        case first
    }

//    var currentSnapshot: Snapshot!
    //    private var themes: [Themes] = []

    // MARK: - Table view data source
    var fetchedResultsController: NSFetchedResultsController<Theme>?

    private func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChangeContentWith snapshot: Snapshot) {
        
        guard let dataSource = tableView?.dataSource as? DiffableDataSource else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }

        let snapshot = snapshot as NSDiffableDataSourceSnapshot<Sections, Theme>
//        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Sections, Themes>
//
//        let reloadIdentifiers: [Themes] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
//            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
//                return nil
//            }
//            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier.objectID), existingObject.isUpdated else { return nil }
//            return itemIdentifier
//        }
//
//        snapshot.reloadItems(reloadIdentifiers)

        let shouldAnimate = tableView?.numberOfSections != 0
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }

//    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.beginUpdates()
//    }
//
//    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
//                           didChange sectionInfo: NSFetchedResultsSectionInfo,
//                           atSectionIndex sectionIndex: Int,
//                           for type: NSFetchedResultsChangeType) {
//        switch type {
//            case .insert:
//                tableView.insertSections([sectionIndex], with: .fade)
//            case .delete:
//                tableView.deleteSections([sectionIndex], with: .fade)
//            case .move:
//                break
//            case .update:
//                break
//            default:
//                break
//        }
//    }
//
//    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
//                           didChange anObject: Any,
//                           at indexPath: IndexPath?,
//                           for type: NSFetchedResultsChangeType,
//                           newIndexPath: IndexPath?) {
//        switch type {
//            case .insert:
//                tableView.insertRows(at: [newIndexPath!], with: .fade)
//            case .delete:
//                tableView.deleteRows(at: [indexPath!], with: .fade)
//            case .update:
//                tableView.reloadRows(at: [indexPath!], with: .fade)
//            case .move:
//                //tableView.moveRow(at: indexPath!, to: newIndexPath!)
//                tableView.deleteRows(at: [indexPath!], with: .fade)
//                tableView.insertRows(at: [newIndexPath!], with: .fade)
//            @unknown default:
//                fatalError("Should never get here")
//        }
//    }
//
//    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
//    }
//
//
//    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.endUpdates()
//    }
}
