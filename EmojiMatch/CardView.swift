//
//  CardView.swift
//

import SwiftUI

struct CardView: View {
    let isFaceUp: Bool
    let emoji: String
    let faceDownColor: Color
    let faceUpColor: Color
    let isHidden: Bool

    // Mirrors the old lift → rotate-out → swap → rotate-in → lower sequence, but as
    // pure functions of (phase, isFaceUp) instead of @State mutated inside nested
    // withAnimation completion closures.
    //
    // `.lifted` and `.lowered` are the two "bookends": `.lifted` reuses the OLD
    // (pre-transition) rotation/visibility values — computed from !isFaceUp — so the
    // lift animates in place before anything rotates. `.lowered` uses the NEW target
    // values, and is what the view sits at between flips.
    private enum FlipPhase: CaseIterable {
        case lifted, rotatingOut, swapFaces, rotatingIn, lowered
    }

    var body: some View {
        Color.clear
            .phaseAnimator(FlipPhase.allCases, trigger: isFaceUp) { content, phase in
                content.overlay(cardContent(phase: phase))
            } animation: { phase in
                animation(for: phase)
            }
    }

    @ViewBuilder
    private func cardContent(phase: FlipPhase) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(faceDownColor)
                .rotation3DEffect(.degrees(backRotation(phase)), axis: (x: 0, y: 1, z: 0), perspective: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(faceUpColor)
                Text(emoji).font(.system(size: 47))
            }
            .opacity(frontVisible(phase) ? 1 : 0)
            .rotation3DEffect(.degrees(frontRotation(phase)), axis: (x: 0, y: 1, z: 0), perspective: 0)
        }
        .scaleEffect(isHidden ? 0.1 : scale(phase))
        .opacity(isHidden ? 0 : 1)
        .animation(.easeIn(duration: 0.2), value: isHidden)
    }

    // MARK: Phase -> value mapping

    private func scale(_ phase: FlipPhase) -> CGFloat {
        switch phase {
        case .lifted, .rotatingOut, .swapFaces, .rotatingIn: 1.15
        case .lowered: 1.0
        }
    }

    // Avoid exactly ±90° — rotation3DEffect produces a singular projection matrix at 90°,
    // which logs "ignoring singular matrix" warnings on every flip. Cosmetic only.
    private func backRotation(_ phase: FlipPhase) -> Double {
        let target: Double = isFaceUp ? 89.9 : 0
        let old: Double = isFaceUp ? 0 : 89.9
        switch phase {
        case .lifted:                          return old
        case .rotatingOut, .swapFaces:         return isFaceUp ? target : old
        case .rotatingIn, .lowered:            return target
        }
    }

    private func frontRotation(_ phase: FlipPhase) -> Double {
        let target: Double = isFaceUp ? 0 : -89.9
        let old: Double = isFaceUp ? -89.9 : 0
        switch phase {
        case .lifted:                          return old
        case .rotatingOut, .swapFaces:         return isFaceUp ? old : target
        case .rotatingIn, .lowered:            return target
        }
    }

    // Keeps the front face invisible while it sits at -89.9°, preventing the
    // sub-pixel-wide rectangle that anti-aliasing renders as a visible line.
    // The swap happens in `.swapFaces`, whose animation is zero-duration —
    // matching the old code's instant (non-animated) visibility toggle.
    private func frontVisible(_ phase: FlipPhase) -> Bool {
        switch phase {
        case .lifted, .rotatingOut:           return !isFaceUp
        case .swapFaces, .rotatingIn, .lowered: return isFaceUp
        }
    }

    private func animation(for phase: FlipPhase) -> Animation? {
        switch phase {
        case .lifted:       .easeIn(duration: 0.2)
        case .rotatingOut:  .easeIn(duration: 0.3)
        case .swapFaces:    .linear(duration: 0)
        case .rotatingIn:   .easeOut(duration: 0.3)
        case .lowered:      .easeOut(duration: 0.2)
        }
    }
}
