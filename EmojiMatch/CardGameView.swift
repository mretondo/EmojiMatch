//
//  CardGameView.swift
//

import SwiftUI

struct CardGameView: View {
    @StateObject private var viewModel: CardGameViewModel

    init(theme: ThemeItem) {
        _viewModel = StateObject(wrappedValue: CardGameViewModel(theme: theme))
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private var bgColor:     Color { Color(uiColor: viewModel.theme.backgroundColor) }
    private var accentColor: Color { Color(uiColor: viewModel.theme.faceDownColor) }

    var body: some View {
        // Capture observed properties here so @Observable registers them as
        // dependencies of this view, not inside GeometryReader's lazy closure.
        let cards = viewModel.cards
        let hiddenIndices = viewModel.hiddenCardIndices
        let isInteractionDisabled = viewModel.isInteractionDisabled
        let score = viewModel.score

        ZStack {
            bgColor.ignoresSafeArea()

            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height
                let scoreColumnWidth: CGFloat = 130
                let gridAvailWidth  = isLandscape ? proxy.size.width - scoreColumnWidth : proxy.size.width
                let gridAvailHeight = isLandscape ? proxy.size.height : proxy.size.height - 70
                let height = cardHeight(gridWidth: gridAvailWidth, gridHeight: gridAvailHeight)

                if isLandscape {
                    HStack(spacing: 0) {
                        grid(cards: cards, hiddenIndices: hiddenIndices,
                             isInteractionDisabled: isInteractionDisabled, cardHeight: height)
                            .frame(width: gridAvailWidth)
                        scoreLabel(score: score)
                            .multilineTextAlignment(.center)
                            .frame(width: scoreColumnWidth)
                    }
                } else {
                    VStack(spacing: 0) {
                        grid(cards: cards, hiddenIndices: hiddenIndices,
                             isInteractionDisabled: isInteractionDisabled, cardHeight: height)
                        Spacer()
                        scoreLabel(score: score)
                            .padding(.bottom)
                    }
                }
            }

            if viewModel.isGameOver {
                Text("Game Over!")
                    .font(.largeTitle).bold()
                    .foregroundStyle(accentColor)
                    .transition(.scale(scale: 0.25).combined(with: .opacity))
            }
        }
        .animation(.spring(dampingFraction: 0.4), value: viewModel.isGameOver)
        .navigationTitle(viewModel.theme.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(bgColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Game") {
                    withAnimation(.easeInOut(duration: 0.3)) { viewModel.newGame() }
                }
                .foregroundStyle(accentColor)
            }
        }
        .onDisappear {
            if viewModel.cards.allSatisfy({ $0.isMatched }) {
                Score.highScore = viewModel.score
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func grid(cards: [Card], hiddenIndices: Set<Int>,
                      isInteractionDisabled: Bool, cardHeight height: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(cards.indices, id: \.self) { index in
                CardView(
                    isFaceUp:      cards[index].isFaceUp || cards[index].isTransitioningToFaceUp,
                    emoji:         viewModel.emoji(for: cards[index]),
                    faceDownColor: Color(uiColor: viewModel.theme.faceDownColor),
                    faceUpColor:   Color(uiColor: viewModel.theme.faceUpColor),
                    isHidden:      hiddenIndices.contains(index)
                )
                .frame(height: height)
                .onTapGesture { viewModel.chooseCard(at: index) }
            }
        }
        .id(viewModel.gameID)           // forces CardView @State reset on new game
        .padding(8)
        .allowsHitTesting(!isInteractionDisabled)
    }

    private func scoreLabel(score: Int64) -> some View {
        Text("Score: \(score)")
            .font(.title)
            .fontWeight(.medium)
            .foregroundStyle(accentColor)
    }

    // MARK: - Layout helpers

    private func cardHeight(gridWidth: CGFloat, gridHeight: CGFloat) -> CGFloat {
        let spacing: CGFloat = 8
        let cols: CGFloat = 4
        let rows: CGFloat = 5
        let cardWidth      = (gridWidth  - spacing * (cols + 1)) / cols
        let heightByAspect = cardWidth * 3 / 4
        let heightBySpace  = (gridHeight - spacing * (rows + 1)) / rows
        return min(heightByAspect, heightBySpace)
    }
}
