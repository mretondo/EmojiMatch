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
    public static var themes: [(themeName: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)] {
        get {
            // theme, emojis, backgroundColor, faceDownColor, faceUpColor
            var themes: [(themeName: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)] = []

            let context = AppDelegate.viewContext
            let request: NSFetchRequest<Themes> = Themes.fetchRequest()

            do {
                let results = try? context.fetch(request)

                if (results != nil) {
                    for result in results! {
                        var theme: (themeName: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)

                        theme.themeName = result.themeName!
                        theme.emojis = result.emojis!
                        theme.backgroundColor = result.backgroundColor as! UIColor
                        theme.faceUpColor = result.faceUpColor as! UIColor
                        theme.faceDownColor = result.faceDownColor as! UIColor

                        themes.append(theme)
                    }
                }
            }

            return themes
        }
    }

    class func populateTable(with newThemes :[(themeName: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)]) throws {
        let context = AppDelegate.viewContext

        try deleteUnusedThemes(newThemes, context: context)
        try addNewThemes(newThemes, context: context)
    }

    ///
    /// delete themes that are no longer used
    ///
    fileprivate static func deleteUnusedThemes(_ themes: [(themeName: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)],
                                               context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Themes> = Themes.fetchRequest()

        do {
            var modified = false
            let results = try context.fetch(request)

            for result in results {
                var found = false

                for theme in themes {
                    if result.themeName == theme.themeName {
                        found = true
                        break
                    }
                }

                if (!found) {
                    context.delete(result)
                    modified = true
                }
            }

            if (modified) {
                try context.save()
            }
        }
    }

    ///
    /// add themes that don't already exist in database
    ///
    fileprivate static func addNewThemes(_ themes: [(themeName: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)],
                                         context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<Themes> = Themes.fetchRequest()

        do {
            var modified = false

            for theme in themes {
                request.predicate = NSPredicate(format: "themeName = %@", theme.themeName)

                let matches = try context.fetch(request)
                if matches.count != 1 {
                    // add theme to table
                    let themes = Themes(context: context)

                    themes.backgroundColor = theme.backgroundColor
                    themes.emojis = theme.emojis
                    themes.faceDownColor = theme.faceDownColor
                    themes.faceUpColor = theme.faceUpColor
                    themes.themeName = theme.themeName

                    modified = true
                }
            }

            if (modified) {
                try context.save()
            }
        }
    }

    public static func printThemesTableStats() {
        #if DEBUG
        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        AppDelegate.viewContext.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? AppDelegate.viewContext.count(for: Themes.fetchRequest()) {
                print ("\(count) Themes records\n")
            } else {
                print ("No Themes records\n")
            }
        }
        #endif
    }
}
