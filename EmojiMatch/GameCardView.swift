import SwiftUI

struct GameCardView: View {
    let viewModel: CardGameViewModel
    let index: Int

    var body: some View {
        // Read state in this view's body so lazy containers cannot reuse a
        // card snapshot whose equality only describes matching-pair identity.
        let card = viewModel.cards[index]

        CardView(
            isFaceUp: card.isFaceUp || card.isTransitioningToFaceUp,
            emoji: viewModel.emoji(for: card),
            faceDownColor: Color(uiColor: viewModel.theme.faceDownColor),
            faceUpColor: Color(uiColor: viewModel.theme.faceUpColor),
            isHidden: viewModel.hiddenCardIndices.contains(index)
        )
    }
}
