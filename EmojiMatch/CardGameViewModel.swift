//
//  CardGameViewModel.swift
//

import Combine
import SwiftUI

final class CardGameViewModel: ObservableObject {
    @Published var cards: [Card] = []
    @Published var score: Int64 = 0
    @Published var isGameOver = false
    @Published var isInteractionDisabled = false
    @Published var hiddenCardIndices: Set<Int> = []
    @Published var gameID = UUID()  // changing this forces CardView @State reset

    let theme: ThemeItem
    private var game: EmojiMatchModel
    private var emojiMap: [Card: String] = [:]
    private var firstTouchedCardIndex: Int?

    init(theme: ThemeItem) {
        self.theme = theme
        let g = EmojiMatchModel(numberOfPairsOfCards: 10)
        game = g
        cards = g.cards
        buildEmojiMap(from: theme.emojis)
    }

    func emoji(for card: Card) -> String {
        emojiMap[card] ?? "?"
    }

    @MainActor
    func chooseCard(at index: Int) {
        guard !isInteractionDisabled else { return }
        let card = cards[index]
        guard !card.isFaceUp && !card.isTransitioningToFaceUp && !card.isMatched else { return }

        if game.indicesOfTransitioningToFaceUpCardsAndFaceUpCards.count == 1 {
            isInteractionDisabled = true
        }

        game.chooseCard(at: index)
        
        // update state so CardView will receive the updated card state after a tap
        cards = game.cards

        let faceUpIndices = game.indicesOfTransitioningToFaceUpCardsAndFaceUpCards
        guard faceUpIndices.count == 2 else {
            firstTouchedCardIndex = index
            return
        }

        Task {
            // Wait for the flip-up animation (0.3s easeIn + 0.3s easeOut = 0.6s total)
            try? await Task.sleep(for: .milliseconds(650))

            let matched = game.cards[index].isMatched

            if matched {
                // Congratulations! you found matching cards and get 1 point
                score += 1

                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.easeIn(duration: 0.2)) {
                    hiddenCardIndices.insert(faceUpIndices[0])
                    hiddenCardIndices.insert(faceUpIndices[1])
                }
                try? await Task.sleep(for: .milliseconds(250))
                resetFaceUp(at: faceUpIndices)

                if game.areAllCardsMatched() {
                    isGameOver = true
                }
            } else {
                applyPenalty(for: index)
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.easeInOut(duration: 0.5)) {
                    resetFaceUp(at: faceUpIndices)
                }
                try? await Task.sleep(for: .milliseconds(550))
                firstTouchedCardIndex = nil
            }

            game.cards[faceUpIndices[0]].hasBeenSeen = true
            game.cards[faceUpIndices[1]].hasBeenSeen = true

            isInteractionDisabled = false
        }
    }

    @MainActor
    func newGame() {
        let g = EmojiMatchModel(numberOfPairsOfCards: 10)
        game = g
        emojiMap = [:]
        buildEmojiMap(from: theme.emojis)
        score = 0
        isGameOver = false
        isInteractionDisabled = false
        firstTouchedCardIndex = nil
        hiddenCardIndices = []
        gameID = UUID()  // forces all CardView @State to reset
        cards = g.cards
    }

    // MARK: - Private

    @MainActor
    private func resetFaceUp(at indices: [Int]) {
        for i in indices {
            game.cards[i].isFaceUp = false
            game.cards[i].isTransitioningToFaceUp = false
        }
        cards = game.cards
    }

    private func buildEmojiMap(from emojiChoices: String) {
        var choices = emojiChoices
        for card in game.cards {
            if emojiMap[card] == nil, !choices.isEmpty {
                let offset = choices.count.random
                let i = choices.index(choices.startIndex, offsetBy: offset)
                emojiMap[card] = String(choices.remove(at: i))
            }
        }
    }

    @MainActor
    private func applyPenalty(for touchedIndex: Int) {
        if AppEnvironment.shared.easyScoringMode {
            if let firstIdx = firstTouchedCardIndex, let twinIdx = game.twinCardIndex(of: firstIdx),
               game.hasCardBeenSeen(at: twinIdx) {
                score -= 1
            } else if game.hasCardBeenSeen(at: touchedIndex) {
                score -= 1
            }
            if score < 0 { score = 0 }
        } else {
            if let firstIdx = firstTouchedCardIndex, let twinIdx = game.twinCardIndex(of: firstIdx),
               game.hasCardBeenSeen(at: twinIdx) {
                score -= 2
            } else if game.hasCardBeenSeen(at: touchedIndex) {
                score -= 1
            }
            if score < -100 { score = -100 }
        }
    }
}
