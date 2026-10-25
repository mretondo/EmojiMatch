//
//  CardGameView.swift
//

import SwiftUI

struct CardGameView: View {
    @State private var viewModel: CardGameViewModel

    init(theme: ThemeItem) {
        _viewModel = State(initialValue: CardGameViewModel(theme: theme))
    }

    @Environment(\.colorScheme) private var colorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private var bgColor:     Color { Color(uiColor: viewModel.theme.backgroundColor) }
    private var accentColor: Color { Color(uiColor: viewModel.theme.faceDownColor) }
    private var navBarColor: Color { colorScheme == .dark ? Color(UIColor.systemBackground) : bgColor }

    var body: some View {
        let cardCount = viewModel.cards.count
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
                        grid(cardCount: cardCount,
                             isInteractionDisabled: isInteractionDisabled, cardHeight: height)
                            .frame(width: gridAvailWidth)
                        scoreLabel(score: score)
                            .multilineTextAlignment(.center)
                            .frame(width: scoreColumnWidth)
                    }
                } else {
                    VStack(spacing: 0) {
                        grid(cardCount: cardCount,
                             isInteractionDisabled: isInteractionDisabled, cardHeight: height)
                        Spacer()
                        scoreLabel(score: score)
                            .padding(.bottom)
                    }
                }
            }

            if viewModel.isGameOver {
                ZStack {
                    SparklesView(themeName: viewModel.theme.name)
                    Text("Game Over!")
                        .font(.largeTitle).bold()
                        .foregroundStyle(accentColor)
                }
                .transition(.scale(scale: 0.25).combined(with: .opacity))
            }
        }
        .animation(.spring(dampingFraction: 0.4), value: viewModel.isGameOver)
        .navigationTitle(viewModel.theme.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(navBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("New Game") {
                    withAnimation(.easeInOut(duration: 0.3)) { viewModel.newGame() }
                }
                .foregroundStyle(accentColor)
            }
        }
        .onChange(of: viewModel.isGameOver) { _, isGameOver in
            if isGameOver {
                Score.highScore = viewModel.score
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func grid(cardCount: Int,
                      isInteractionDisabled: Bool, cardHeight height: CGFloat) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<cardCount, id: \.self) { index in
                GameCardView(viewModel: viewModel, index: index)
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
        // NOTE: GeometryReader always fires an initial layout pass with a zero size before it knows its real bounds.

        // check for invalid frame dimension on first GeometryReader pass
        guard gridWidth > 0, gridHeight > 0 else { return 1 }

        let spacing: CGFloat = 8
        let cols: CGFloat = 4
        let rows: CGFloat = 5
        let cardWidth      = (gridWidth  - spacing * (cols + 1)) / cols
        let heightByAspect = cardWidth * 3 / 4
        let heightBySpace  = (gridHeight - spacing * (rows + 1)) / rows

        // the max(1, ...) ensures the frame height is always a valid positive value during the first pass
        return max(1, min(heightByAspect, heightBySpace))
    }
}

// MARK: - Sparkles

private struct SparklesView: View {
    let themeName: String
//    @Environment(\.colorScheme) private var colorScheme

    private var sparkleColor: Color {
        let lower = themeName.lowercased()
        if lower.contains("christmas") || lower.contains("halloween") {
            return Color.white.opacity(0.85)
        }
        return Color.yellow.opacity(0.85)
    }

    private let angles:  [Double] = stride(from: 0, to: 360, by: 30).map { $0 }
    private let radii:   [Double] = [80, 110, 70, 95, 120, 65, 100, 75, 115, 85, 105, 90]
    private let sizes:   [CGFloat] = [16, 12, 20, 14, 10, 18, 15, 22, 11, 17, 13, 19]
    private let periods: [Double] = [1.2, 0.9, 1.4, 1.0, 1.3, 0.8, 1.1, 1.5, 0.95, 1.25, 1.05, 0.85]
    private let offsets: [Double] = [0.0, 0.3, 0.6, 0.9, 0.12, 0.45, 0.78, 0.21, 0.54, 0.87, 0.15, 0.48]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    let phase = ((t / periods[i]) + offsets[i]).truncatingRemainder(dividingBy: 1)
                    let intensity = sin(phase * .pi)
                    Image(systemName: "sparkle")
                        .font(.system(size: sizes[i]))
                        .foregroundStyle(sparkleColor)
                        .scaleEffect(max(0.05, intensity))
                        .opacity(max(0, intensity))
                        .offset(
                            x: cos(angles[i] * .pi / 180) * radii[i],
                            y: sin(angles[i] * .pi / 180) * radii[i]
                        )
                }
            }
        }
    }
}
