//
//  Theme+CoreDataClass.swift
//  Match Emojis
//
//  Created by Mike Retondo on 9/30/22.
//
//

import Foundation
import CoreData
import UIKit

struct ThemeProperties: Hashable {
    var name: String
    var emojis: String
    var backgroundColor: UIColor
    var faceDownColor: UIColor
    var faceUpColor: UIColor

    let identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: ThemeProperties, rhs: ThemeProperties) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

public class Theme: NSManagedObject {
    static var defaultThemes = [
        // name, emojis, backgroundColor, faceDownColor, faceUpColor
        ThemeProperties(name: "Sports", emojis: "🏀🏈⚾️🏊‍♀️🏌️‍♂️🚴‍♀️🏸🏒🏄‍♀️🎯🎳🏇🏂⛷🏋🏻‍♂️🤸‍♂️⛹️‍♂️🎾🏓⚽️🏏🛹🏹⛸🥌", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Animals", emojis: "🐶🐠🦊🐻🐨🐒🐸🐤🐰🐽🦆🦅🦋🐞🐌🐺🦖🕷🦞🐬🐫🦒🦜🐎🐄", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Faces", emojis: "😃🤣😍🤢🤪🤓😬🙄😡😎🥶🤥😇🤠🤮🙁😤😫🥳😁😮🤐😳😅🥺", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Christmas", emojis: "🎅🏻🧣🎄❄️⛄️🎁🌨☃️🤶🏻🧤", backgroundColor: #colorLiteral(red: 0, green: 0.2784313725, blue: 0.1529411765, alpha: 1), faceDownColor: #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1), faceUpColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)),
        ThemeProperties(name: "Halloween", emojis: "🎃🦇😱🙀😈👻🍭🍬🍎🧛🏻‍♂️🧟‍♂️👺⚰️", backgroundColor: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), faceDownColor: #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1), faceUpColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)),
        ThemeProperties(name: "Food", emojis: "🍏🍎🍋🍉🍇🍒🥥🥑🥦🌽🥕🥯🥨🥩🍗🌭🍔🍟🍕🌮🍦🧁🍰🎂🍭🍩☕️🍺🧀🍌🌶🍅🥒🍊", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Travel", emojis: "🚗🚌🏎🚑🚒🚜🛴🚲🛵🚔🚠🚃🚂✈️🛩🛰🚀🛸🚁🛶⛵️🛳🚦🗽🗿🏰🏯🎢🏝🌋⛺️🏠🏛🕌⛩", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Flags", emojis: "🏴‍☠️🚩🏳️‍🌈🇺🇸🇨🇦🇫🇷🇨🇳🇷🇺🇮🇳🇮🇱🇯🇵🇮🇹🎌🇲🇾🇲🇽🇳🇵🇳🇴🇵🇦🇨🇭🇬🇧🏁🇮🇪🇲🇾🇻🇳🇧🇩", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Objects", emojis: "⌚️📱💻⌨️🖥🖨🕹🗜📀📸🎥📽🎞📞📺🧭⏰⏳📡🔦🧯🛠🧲🧨💈💊🛎🛏🛒📭📜📆📌🔍🔐🚿🧬📋📎🧷🧮🔬", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
        ThemeProperties(name: "Potpourri", emojis: "🌎🍎🦕🧵🌴🌭🚀❤️🍿⭐️🥶🍉🎓🕶🤡🐝🦄🍄🌈😎🌹☔️🍪🎲🎱🥁🛵✈️🏰⛵️💾💡✏️💰🔔🥨🇺🇸📫🍒🏆👽👍🧑‍🚒👠", backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1), faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)),
    ]

    class var themes: [ThemeProperties] {
        get {
            var themes: [ThemeProperties] = []

            let moc = AppDelegate.moc
            let request = fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            if let results = try? moc.fetch(request) {
                for result in results {
                    let theme = ThemeProperties (
                        name: result.name!,
                        emojis: result.emojis!,
                        backgroundColor: result.backgroundColor as! UIColor,
                        faceDownColor: result.faceDownColor as! UIColor,
                        faceUpColor: result.faceUpColor as! UIColor
                    )

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

            let moc = AppDelegate.moc
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

    class func theme(forName name: String) -> ThemeProperties? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "name = %@", name)
        let moc = AppDelegate.moc

        if let results = try? moc.fetch(request) {
            if let result = results.first {
                let theme = ThemeProperties (
                    name: result.name!,
                    emojis: result.emojis!,
                    backgroundColor: result.backgroundColor as! UIColor,
                    faceDownColor: result.faceDownColor as! UIColor,
                    faceUpColor: result.faceUpColor as! UIColor
                )

                return theme
            }
        }

        return nil
    }

    ///
    /// create the Theme entity if it doesn't exist then add the new themes and delete old unused themes
    ///
    class func updateDatabase(with themes: [ThemeProperties]) throws {
        //        try removeAllData()
        try deleteUnusedThemes(themes)
        try addNewThemes(themes)
    }

    ///
    /// remove all data from themes
    ///
    class func removeAllData() throws {
        let moc = AppDelegate.moc

        let request: NSFetchRequest<NSFetchRequestResult> = fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

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
    class func deleteUnusedThemes(_ themes: [ThemeProperties]) throws {
        let moc = AppDelegate.moc

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
    class func addNewThemes(_ themes: [ThemeProperties]) throws {
        let moc = AppDelegate.moc

        let request = fetchRequest()

        for theme in themes {
            request.predicate = NSPredicate(format: "name = %@", theme.name)
            let matches = try moc.fetch(request)

            if matches.count != 1 {
                // theme doesn't exist so add it
                let themes = Theme(context: moc)

                themes.backgroundColor  = theme.backgroundColor
                themes.emojis           = theme.emojis
                themes.faceDownColor    = theme.faceDownColor
                themes.faceUpColor      = theme.faceUpColor
                themes.name             = theme.name
            }
        }
    }
}
