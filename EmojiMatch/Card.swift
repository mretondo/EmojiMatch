//
//  Card.swift
//

import Foundation

struct Card: Hashable
{
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    var isFaceUp = false {
        didSet {
            if isFaceUp {
                startUsingBonusTime()
            } else {
                stopUsingBonusTime()
            }
        }
    }

    var isTransitioningToFaceUp = false

    var isMatched = false {
        didSet {
            stopUsingBonusTime()
        }
    }

    var hasBeenSeen = false

    private var identifier: Int
    
    // Thread-safe identifier generation using actor
    private static let identifierFactory = IdentifierFactory()
    
    private static func getUniqueIdentifier() -> Int {
        // Since Card creation happens synchronously, we need a synchronous approach
        // Using a lock-protected counter instead
        return identifierFactory.next()
    }
    
    init() {
        self.identifier = Card.getUniqueIdentifier()
    }

    // MARK: - Bonus Time

    // this could give matching bonus points if the user matches the card
    // before a certain amount of time passes during which the card is face up

    // can be zero which means "no bonus available" for this card
    var bonusTimeLimit: TimeInterval = 6

    // how long this card has ever been face up
    private var faceUpTime: TimeInterval {
        if let lastFaceUpDate = lastFaceUpDate {
            return pastFaceUpTime + Date().timeIntervalSince(lastFaceUpDate)
        } else {
            return pastFaceUpTime
        }
    }

    // the last time this card was turned face up (and is still face up)
    var lastFaceUpDate: Date?

    // the accumulated time this card has been face up in the past
    // (i.e. not including the current time it's been face up if it is currently so)
    var pastFaceUpTime: TimeInterval = 0

    // how much time left before the bonus opportunity runs out
    var bonusTimeRemaining: TimeInterval {
        max(0, bonusTimeLimit - faceUpTime)
    }

    // percentage of the bonus time remaining
    var bonusRemaining: Double {
        (bonusTimeLimit > 0 && bonusTimeRemaining > 0) ? bonusTimeRemaining / bonusTimeLimit : 0
    }

    // whether the card was matched during the bonus time period
    var hasEarnedBonus: Bool {
        isMatched && bonusTimeRemaining > 0
    }

    // whether we are currently face up, unmatched and have not yet used up the bonus window
    var isConsumingBonusTime: Bool {
        isFaceUp && !isMatched && bonusTimeRemaining > 0
    }

    // called when the card transitions to face up state
    private mutating func startUsingBonusTime() {
        if isConsumingBonusTime, lastFaceUpDate == nil {
            lastFaceUpDate = Date()
        }
    }

    // called when the card goes back face down (or gets matched)
    private mutating func stopUsingBonusTime() {
        pastFaceUpTime = faceUpTime
        lastFaceUpDate = nil
    }
}

// Thread-safe identifier generator
private final class IdentifierFactory: @unchecked Sendable {
    private var counter = 0
    private let lock = NSLock()
    
    func next() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let value = counter
        counter += 1
        return value
    }
}

