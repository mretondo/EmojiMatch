//
//  EmojiMatch.swift
//
//  This is the data Model
//

import Foundation

struct EmojiMatch
{
	private(set) var cards = [Card]()
    
    private var indexOfOneAndOnlyFaceUpCard: Int? {
        get { return cards.indices.filter { cards[$0].isFaceUp}.oneAndOnly }
        
        set {
            for i in cards.indices {
                cards[i].isFaceUp = (i == newValue)
            }            
        }
    }
	
	mutating func chooseCard(at index: Int) {
        assert(cards.indices.contains(index), "EmojiMatch(at \(index)): chosen index not in cards")
		if !cards[index].isMatched {
			if let matchIndex = indexOfOneAndOnlyFaceUpCard, matchIndex != index {
				// check if cards match
				if cards[matchIndex] == cards[index] {
					cards[matchIndex].isMatched = true
					cards[index].isMatched = true
				}
				cards[index].isFaceUp = true
			} else {
				indexOfOneAndOnlyFaceUpCard = index
			}
			
		}
	}
	
	init(numberOfPairsOfCards: Int) {
        assert(numberOfPairsOfCards > 0, "EmojiMatch.init(\(numberOfPairsOfCards)): must have at lease one pair of cards")
		for _ in 1...numberOfPairsOfCards {
			let card = Card()
			cards += [card, card]
		}

        // cards are now in order like (1-1, 2-2, 3-3,...) and need to be suffled
        cards.shuffle()
	}
	
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d = Int(arc4random_uniform(numericCast(unshuffledCount)))
//            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

extension Collection {
    var oneAndOnly: Element? {
        return count == 1 ? first : nil
    }
}






