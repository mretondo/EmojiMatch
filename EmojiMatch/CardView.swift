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

    // Tracks the pre-transition value of isFaceUp. Seeded to match isFaceUp on
    // init (so the very first render has no "phantom" prior transition), then
    // updated to the OLD value the instant isFaceUp changes — so it always lags
    // exactly one transition behind, which is what `.lifted`/`.rotatingOut`
    // need to reconstruct the settled look from *before* this flip started.
    //
    // Reset back to equal isFaceUp once the phase machine reaches `.lowered`
    // (see the `.task(id: phase)` below) — not on a fixed timer, since any
    // wall-clock guess can race against unrelated ancestor state changes
    // (e.g. score/isInteractionDisabled updates in the view model) that also
    // land around the same offset and force a re-render. PhaseAnimator can
    // spuriously replay an early phase like `.lifted` with an unchanged
    // trigger when that happens, and without settling first that replay
    // would visibly re-run the flip instead of being a no-op.
    @State private var previousIsFaceUp: Bool

    init(isFaceUp: Bool, emoji: String, faceDownColor: Color, faceUpColor: Color, isHidden: Bool) {
        self.isFaceUp = isFaceUp
        self.emoji = emoji
        self.faceDownColor = faceDownColor
        self.faceUpColor = faceUpColor
        self.isHidden = isHidden
        self._previousIsFaceUp = State(initialValue: isFaceUp)
    }

    // Mirrors the old lift → rotate-out → swap → rotate-in → lower sequence, but as
    // pure functions of (phase, isFaceUp, previousIsFaceUp) instead of @State mutated
    // inside nested withAnimation completion closures.
    //
    // `.lifted` and `.lowered` are the two "bookends": `.lifted` reuses the OLD
    // (pre-transition) rotation/visibility values — computed from previousIsFaceUp —
    // so the lift animates in place before anything rotates. `.lowered` uses the NEW
    // target values, and is what the view sits at between flips.
    private enum FlipPhase: CaseIterable {
        case lifted, rotatingOut, swapFaces, rotatingIn, lowered
    }

    // The `.frame(maxWidth: .infinity, maxHeight: .infinity)` on the base view is
    // required: phaseAnimator's internal proxy doesn't reliably negotiate size with
    // its parent the way a plain view does, so without an explicit greedy frame the
    // whole card (and the overlay built from it) collapses to a tiny box instead of
    // filling the grid cell.
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .phaseAnimator(FlipPhase.allCases, trigger: isFaceUp) { content, phase in
                content
                    .overlay(cardContent(phase: phase))
                    .task(id: phase) {
                        // .lowered's rendering never reads previousIsFaceUp (see
                        // backRotation/frontRotation/scale below), so settling here
                        // has no visual effect on the phase currently on screen —
                        // it only defuses any *future* spurious replay.
                        if phase == .lowered {
                            previousIsFaceUp = isFaceUp
                        }
                    }
            } animation: { phase in
                animation(for: phase)
            }
            .onChange(of: isFaceUp) { oldValue, _ in
                previousIsFaceUp = oldValue
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
        case .lifted, .rotatingOut, .swapFaces, .rotatingIn:
            previousIsFaceUp != isFaceUp ? 1.15 : 1.0
        case .lowered: 1.0
        }
    }

    // Avoid exactly ±90° — rotation3DEffect produces a singular projection matrix at 90°,
    // which logs "ignoring singular matrix" warnings on every flip. Cosmetic only.
    private func backRotation(_ phase: FlipPhase) -> Double {
        let target: Double = isFaceUp ? 89.9 : 0
        let old: Double = previousIsFaceUp ? 89.9 : 0
        switch phase {
        case .lifted:                          return old
        case .rotatingOut, .swapFaces:         return isFaceUp ? target : old
        case .rotatingIn, .lowered:            return target
        }
    }

    private func frontRotation(_ phase: FlipPhase) -> Double {
        let target: Double = isFaceUp ? 0 : -89.9
        let old: Double = previousIsFaceUp ? 0 : -89.9
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
        case .lifted, .rotatingOut:             return previousIsFaceUp
        case .swapFaces, .rotatingIn, .lowered: return isFaceUp
        }
    }

    private func animation(for phase: FlipPhase) -> Animation? {
        switch phase {
        case .lifted:       .easeIn(duration: 0.2)
        case .rotatingOut:  .easeIn(duration: 0.3)
        // A truly zero-duration animation can make PhaseAnimator's completion-based
        // advance never fire, stalling the cycle at this phase (card appears stuck
        // lifted, since .swapFaces shares the enlarged scale with the other phases).
        case .swapFaces:    .linear(duration: 0.01)
        case .rotatingIn:   .easeOut(duration: 0.3)
        case .lowered:      .easeOut(duration: 0.2)
        }
    }
}
