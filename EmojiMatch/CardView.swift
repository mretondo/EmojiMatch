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

    @State private var backRotation  = 0.0
    @State private var frontRotation = -90.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(faceDownColor)
                .rotation3DEffect(.degrees(backRotation), axis: (x: 0, y: 1, z: 0))

            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(faceUpColor)
                Text(emoji).font(.system(size: 40))
            }
            .rotation3DEffect(.degrees(frontRotation), axis: (x: 0, y: 1, z: 0))
        }
        .scaleEffect(isHidden ? 0.1 : 1.0)
        .opacity(isHidden ? 0 : 1)
        .animation(.easeIn(duration: 0.2), value: isHidden)
        .onChange(of: isFaceUp) { _, newValue in
            if newValue {
                withAnimation(.easeIn(duration: 0.3), completionCriteria: .logicallyComplete) {
                    backRotation = 90
                } completion: {
                    withAnimation(.easeOut(duration: 0.3)) { frontRotation = 0 }
                }
            } else {
                withAnimation(.easeIn(duration: 0.3), completionCriteria: .logicallyComplete) {
                    frontRotation = -90
                } completion: {
                    withAnimation(.easeOut(duration: 0.3)) { backRotation = 0 }
                }
            }
        }
    }
}
