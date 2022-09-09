//
//  Themes.swift
//  Match Emojis
//
//  Created by Mike Retondo on 9/7/19.
//

import UIKit
import CoreData

class Themes: NSManagedObject
{
    class var themes: [(name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)] {
        get {
            // theme, emojis, backgroundColor, faceDownColor, faceUpColor
            var themes: [(name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)] = []

            let moc = AppDelegate.viewContext
            let request = fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            if let results = try? moc.fetch(request) {
                for result in results {
                    var theme: (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)

                    theme.name = result.name!
                    theme.emojis = result.emojis!
                    theme.backgroundColor = result.backgroundColor as! UIColor
                    theme.faceUpColor = result.faceUpColor as! UIColor
                    theme.faceDownColor = result.faceDownColor as! UIColor

                    themes.append(theme)
                }
            }

            return themes
        }
    }

    class var namesAndEmojis: [(name: String, emojis: String)] {
        get {
            // theme name, emojis
            var themeNames: [(name: String, emojis: String)] = []

            let moc = AppDelegate.viewContext
            let request = fetchRequest()
            request.propertiesToFetch = ["name", "emojis"]
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            if let results = try? moc.fetch(request) {
                for result in results {
                    var themeName: (name: String, emojis: String)

                    themeName.name = result.name!
                    themeName.emojis = result.emojis!

                    themeNames.append(themeName)
                }
            }

            return themeNames
        }
    }

    class func theme(forName name: String) -> (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "name = %@", name)
        let moc = AppDelegate.viewContext

        if let results = try? moc.fetch(request) {
            if let result = results.first {
                // theme name, emojis, backgroundColor, faceDownColor, faceUpColor
                var theme: (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)

                theme.name = result.name!
                theme.emojis = result.emojis!
                theme.backgroundColor = result.backgroundColor as! UIColor
                theme.faceUpColor = result.faceUpColor as! UIColor
                theme.faceDownColor = result.faceDownColor as! UIColor

                return theme
            }
        }

        return nil
    }

    ///
    /// create the Themes entity if it doesn't exist then add the new themes and delete old unused themes
    ///
    class func updateDatabase(with themes: [(name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)]) throws {
//        try removeAllData()
        try deleteUnusedThemes(themes)
        try addNewThemes(themes)
    }

    ///
    /// remove all data from themes
    ///
    class func removeAllData() throws {
        let moc = AppDelegate.viewContext

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Themes.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try moc.persistentStoreCoordinator!.execute(deleteRequest, with: moc)
            #if DEBUG
            print ("Removed All Theme Data\n")
            #endif
        } catch let error as NSError {
            #if DEBUG
            print ("removeAllData() - \(error.localizedDescription)\n")
            #endif
        }
    }

    ///
    /// delete themes that are no longer used
    ///
    class func deleteUnusedThemes(_ themes: [(name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)]) throws {
        let moc = AppDelegate.viewContext

        let request = fetchRequest()
        let results = try moc.fetch(request)

        for result in results {
            var found = false

            for theme in themes {
                if result.name == theme.name {
                    found = true
                    break
                }
            }

            if !found {
                moc.delete(result)
            }
        }
    }

    ///
    /// add themes that don't already exist in database
    ///
    class func addNewThemes(_ themes: [(name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)]) throws {
        let moc = AppDelegate.viewContext

        let request = fetchRequest()

        for theme in themes {
            request.predicate = NSPredicate(format: "name = %@", theme.name)
            let matches = try moc.fetch(request)

            if matches.count != 1 {
                // theme doesn't exist so add it
                let themes = Themes(context: moc)

                themes.backgroundColor  = theme.backgroundColor
                themes.emojis           = theme.emojis
                themes.faceDownColor    = theme.faceDownColor
                themes.faceUpColor      = theme.faceUpColor
                themes.name             = theme.name
            }
        }
    }
}
