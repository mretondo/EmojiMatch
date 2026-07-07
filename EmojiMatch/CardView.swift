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

    // Avoid exactly ±90° — rotation3DEffect produces a singular projection matrix at 90°,
    // which logs "ignoring singular matrix" warnings on every flip.
    @State private var backRotation  = 0.0
    @State private var frontRotation = -89.9

    // Keeps the front face invisible while it sits at -89.9°, preventing the
    // sub-pixel-wide rectangle that anti-aliasing renders as a visible line.
    @State private var frontVisible  = false

    // Lifts the card off the table before flipping, then settles it back down
    // after — mirrors liftCardUp/flipCardOver/lowerCardDown from the UIKit version.
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(faceDownColor)
                // perspective: 0 = orthographic projection; avoids the foreshortening
                // artifact that made the near-90° sliver bright/visible.
                .rotation3DEffect(.degrees(backRotation), axis: (x: 0, y: 1, z: 0), perspective: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(faceUpColor)
                Text(emoji).font(.system(size: 47))
            }
            .opacity(frontVisible ? 1 : 0)
            .rotation3DEffect(.degrees(frontRotation), axis: (x: 0, y: 1, z: 0), perspective: 0)
        }
        .scaleEffect(isHidden ? 0.1 : scale)
        .opacity(isHidden ? 0 : 1)
        .animation(.easeIn(duration: 0.2), value: isHidden)
        .onChange(of: isFaceUp) { _, newValue in
            if newValue {
                // Phase 1: lift the card up off the table (easeIn)
                withAnimation(.easeIn(duration: 0.2), completionCriteria: .logicallyComplete) {
                    scale = 1.15
                } completion: {
                    // Phase 2: rotate back face to near-90° (easeIn)
                    withAnimation(.easeIn(duration: 0.3), completionCriteria: .logicallyComplete) {
                        backRotation = 89.9
                    } completion: {
                        // Phase 3: make front face visible and rotate it into view (easeOut).
                        // Reset frontRotation first (no animation) so it starts at -89.9°,
                        // then reveal it the instant the outward rotation begins.
                        frontRotation = -89.9
                        frontVisible = true
                        withAnimation(.easeOut(duration: 0.3), completionCriteria: .logicallyComplete) {
                            frontRotation = 0
                        } completion: {
                            // Phase 4: lower the card back down onto the table (easeOut)
                            withAnimation(.easeOut(duration: 0.2)) { scale = 1.0 }
                        }
                    }
                }
            } else {
                // Phase 1: lift the card up off the table (easeIn)
                withAnimation(.easeIn(duration: 0.2), completionCriteria: .logicallyComplete) {
                    scale = 1.15
                } completion: {
                    // Phase 2: rotate front face back to near-90° (easeIn)
                    withAnimation(.easeIn(duration: 0.3), completionCriteria: .logicallyComplete) {
                        frontRotation = -89.9
                    } completion: {
                        // Phase 3: hide front face before rotating back face into view,
                        // so the invisible face never shows the anti-aliased line.
                        frontVisible = false
                        withAnimation(.easeOut(duration: 0.3), completionCriteria: .logicallyComplete) {
                            backRotation = 0
                        } completion: {
                            // Phase 4: lower the card back down onto the table (easeOut)
                            withAnimation(.easeOut(duration: 0.2)) { scale = 1.0 }
                        }
                    }
                }
            }
        }
    }
}
