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
}
