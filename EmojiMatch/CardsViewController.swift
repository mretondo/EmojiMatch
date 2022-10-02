//
//  CardsViewController.swift
//

import UIKit
import Foundation
import CoreData

class CardsViewController: UIViewController
{
    @IBOutlet private weak var scoreLabel: UILabel! { didSet { updateScoreLabel() } }
    @IBOutlet private var cardButtons: [UIButton]!
    @IBOutlet private weak var gameOver: UILabel!

    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet { updateViewFromModel(touchedCard: nil) }
    }

    // sets the current theme and get ready for new game
    var theme: (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)? {
        didSet {
            view.backgroundColor = theme?.backgroundColor
            emojiChoices = theme?.emojis ?? ""

            updateViewFromModel(touchedCard: nil)
        }
    }

    private(set) var score: Int64 = 0 { didSet { updateScoreLabel() } }
    private var flipCompleted = false
    private var emojiChoices = ""
    private var emoji: [Card : String] = [:]
    private var seenCards: [Card : Bool] = [:]
    private lazy var game = EmojiMatchModel(numberOfPairsOfCards: (cardButtons.count + 1) / 2)

    @IBAction private func touchCard(_ sender: UIButton) {
        // ignore touches after game is over
        guard self.gameOver.isHidden else { return }

        guard let cardNumber = cardButtons.firstIndex(of: sender) else {
            #if DEBUG
            print("touchCard(_:) - choosen card was not in cardButtons")
            #endif
            return
        }

        let card = game.cards[cardNumber]
        guard !card.isFaceUp && !card.isTransitioningToFaceUp else { return } // ignore touches on Transitioning/face up cards

        // if two cards have not finished flipping back down then wait for them to finish before processing new touched card
        if flipCompleted {
            flipCompleted = false
        } else if game.indicesOfTransitioningToFaceUpCardsAndFaceUpCards.count == 2 {
            // async alows previous cards flipping animation to
            // complete before starting animation of third card.
            DispatchQueue.main.async {
                self.touchCard(sender)
            }

            return  // consume event
        }

        // if card isMatched then it can't be pressed
        if !card.isMatched {
            game.chooseCard(at: cardNumber)

            // get union of arrarys
            let indicesOfFaceUpCards = game.indicesOfTransitioningToFaceUpCardsAndFaceUpCards

            if game.cards[cardNumber].isMatched {
                // Congradulations! you found matching cards and get 2 points
                score += 2

                game.cards[indicesOfFaceUpCards[0]].hasBeenSeen = true
                game.cards[indicesOfFaceUpCards[1]].hasBeenSeen = true
            }
            else {
                // deduct points if 2 cards are face up and don't match
                if indicesOfFaceUpCards.count == 2 {
                    // loose a point for each card that was seen before
                    if game.cards[indicesOfFaceUpCards[0]].hasBeenSeen {
                        score -= 1
                    } else {
                        game.cards[indicesOfFaceUpCards[0]].hasBeenSeen = true
                    }

                    if game.cards[indicesOfFaceUpCards[1]].hasBeenSeen {
                        score -= 1
                    } else {
                        game.cards[indicesOfFaceUpCards[1]].hasBeenSeen = true
                    }

                    // cap lowest score to -100
                    if score < LeaderboardTableViewController.lowestScorePosible {
                        score = LeaderboardTableViewController.lowestScorePosible
                    }
                }
            }

            updateViewFromModel(touchedCard: cardNumber)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set view title to the theme's name
        title = theme?.name

        setButtonsFontSize()

        setupNewGame()
    }

//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        if title == "Christmas" || title == "Halloween" {
//            return .darkContent
//        } else {
//            return .default
//        }
//    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // change the titles text color for Christmas and Halloween
        if title == "Christmas" || title == "Halloween", let theme = theme {
            if #available(iOS 13.0, *) {
//                let appearance = UINavigationBarAppearance(idiom: .phone)
//                appearance.largeTitleTextAttributes = [.foregroundColor : theme.faceDownColor]
//                appearance.titleTextAttributes = [.foregroundColor : theme.faceDownColor]
//
//                navigationItem.standardAppearance = appearance

                navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor : theme.faceDownColor]
                navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : theme.faceDownColor]
                navigationController?.navigationBar.barStyle = .black
            } else {
                // Fallback on earlier versions
                if let navigationBar = navigationController?.navigationBar {
                    // change the titles text color for Christmas and Halloween
                    navigationBar.largeTitleTextAttributes = [.foregroundColor : theme.faceDownColor]
                    navigationBar.titleTextAttributes = [.foregroundColor : theme.faceDownColor]
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if areAllCardsMatched() {
            AppDelegate.highScore = score
            try? AppDelegate.moc.save()
        }

        // reset titles text to default color if changed in viewWillAppear
//        navigationController?.navigationBar.largeTitleTextAttributes = nil
//        navigationController?.navigationBar.titleTextAttributes = nil
        navigationController?.navigationBar.largeTitleTextAttributes = [:]
        navigationController?.navigationBar.titleTextAttributes = [:]
        navigationController?.navigationBar.barStyle = .default
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setButtonsFontSize()
    }

    @IBAction func newGame(_ sender: UIBarButtonItem) {
        // scale all cards to zero size so we can zoom cards back out
        for index in cardButtons.indices {
            cardButtons[index].transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            cardButtons[index].alpha = 0.0
            cardButtons[index].isOpaque = false
        }

        UIView.animate(withDuration: 0.6, delay: 0.2, options: [.curveEaseOut]) { [self] in
            setupNewGame()
            updateViewFromModel(touchedCard: nil)
        }
    }

    fileprivate func setupGameOverLabel() {
        self.gameOver.isHidden = true

        // zoom in gameOver label 4X
        let scale = CGAffineTransform(scaleX: 0.25, y: 0.25)
        // rotate label upsidedown
        let rotationAngle = CGAffineTransform(rotationAngle: .pi)

        UIView.animate(withDuration: 0.0) {
            self.gameOver.transform = scale.concatenating(rotationAngle)
        }
    }

    fileprivate func setupButtonsDefaults() {
        // setup buttons to start of game defaults
        for index in cardButtons.indices {
            cardButtons[index].transform = .identity
            cardButtons[index].isOpaque = true
            cardButtons[index].alpha = 1.0
            cardButtons[index].setTitle("", for: .normal)
            cardButtons[index].backgroundColor = theme?.faceDownColor
        }
    }

    private func setupNewGame() {
        setupGameOverLabel()

        setupButtonsDefaults()

        score = 0
        flipCompleted = false
        emojiChoices = theme?.emojis ?? ""
        emoji = [:]
        seenCards = [:]
        game = EmojiMatchModel(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
    }

    private func updateScoreLabel() {
        if let theme = theme {
            var attributes: [ NSAttributedString.Key : Any ] = [:]

            if theme.backgroundColor == #colorLiteral(red: 0, green: 0.2784313725, blue: 0.1529411765, alpha: 1) /* dark green for Christmas */ {
                attributes = [ .foregroundColor : theme.faceDownColor as Any ]
            } else if theme.backgroundColor == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) /* black for Holloween */ {
                attributes = [ .foregroundColor : theme.faceDownColor as Any ]
            } else {
                attributes = [ .strokeWidth: 2.0, .strokeColor: theme.faceDownColor ]
            }

            let attributedString = NSAttributedString(
                string: traitCollection.verticalSizeClass == .compact ? "Score\n\(score)" : "Score: \(score)",
                attributes: attributes)

            scoreLabel.attributedText = attributedString
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateScoreLabel()
    }

    private func setButtonsFontSize() {
        if cardButtons != nil {
            for index in cardButtons.indices {
                let button = cardButtons[index]
                
                if var font = button.titleLabel?.font {
                    let defaultFontSize: CGFloat = 46.0

//                    let deviceType = "\(UIDevice().type)"
//                    if  deviceType.starts(with: "iPhone3") ||
//                        deviceType.starts(with: "iPhone4") ||
//                        deviceType.starts(with: "iPhone5") ||
//                        deviceType.starts(with: "iPhone6") {
//                        if UIDevice.current.orientation.isLandscape {
//                            font = font.withSize(defaultFontSize - 14)
//                        } else {
//                            font = font.withSize(defaultFontSize)
//                        }
//                    } else {
                        if UIDevice.current.orientation.isLandscape {
                            font = font.withSize(defaultFontSize - 6)
                        } else {
                            font = font.withSize(defaultFontSize)
                        }
//                    }

                    button.titleLabel?.font = font
                }
            }
        }
    }

    private func updateViewFromModel(touchedCard: Int?) {
        if cardButtons != nil {
            //
            // update all buttons
            //
            for index in cardButtons.indices {
                let button = cardButtons[index]
                let card = game.cards[index]

                if touchedCard != nil && (card.isTransitioningToFaceUp || card.isFaceUp) {
                    if touchedCard == index {
                        #if DEBUG
                        print("isTransitioningToFaceUp 1")
                        #endif
                        // card has been tapped and needs to flip up
                        animateFlippingCardUp(card, button)
                    } else {
                        // card is face up or TransitioningToFaceUp so show the emoji
                        button.setTitle(emoji(for: card), for: .normal)
                        button.backgroundColor = theme?.faceUpColor
                    }
                } else {
                    // card is face down so no emoji to show
                    button.setTitle("", for: .normal)
                    // if card isMatched then it's effectively hidden i.e transparent
                    button.backgroundColor = card.isMatched ? #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 0) : theme?.faceDownColor
                }
            }
        }
    }

    fileprivate func animateFlippingCardUp(_ card: Card, _ button: UIButton) {
        // 1 - lift the card
        #if DEBUG
        print("lift the card 1")
        #endif
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: { button.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) },
            completion: { finished in
                // after card is lifted then change the title and background - this will be the FlipTo side
                button.setTitle(self.emoji(for: card), for: .normal)
                button.backgroundColor = self.theme?.faceUpColor

                // 2 - flip the card
                #if DEBUG
                print("flip the card 2")
                #endif
                UIView.transition(
                    with: button,
                    duration: 0.6,
                    options: [.transitionFlipFromLeft, .curveEaseInOut],
                    animations: nil,
                    completion: { finished in
                        // 3 - set card back down
                        #if DEBUG
                        print("lower the card 3")
                        #endif
                        UIView.animate(
                            withDuration: 0.2,
                            delay: 0,
                            options: .curveEaseOut,
                            animations: { button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) },
                            completion: { finished in
                                if let index = self.cardButtons.firstIndex(of: button) {
                                    self.game.cards[index].isTransitioningToFaceUp = false
                                    self.game.cards[index].isFaceUp = true
                                }

                                // hide cards if matched
                                if card.isMatched {
                                    let indicesOfCards = self.game.indicesOfCard(card)

                                    if let firstIndex = indicesOfCards.0, let secondIndex = indicesOfCards.1 {
                                        UIView.animate(
                                            withDuration: 0.0,
                                            delay: 0.3,
                                            options: [.curveLinear],
                                            animations: {
                                                self.cardButtons[firstIndex].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                                                self.cardButtons[secondIndex].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                                            },
                                            completion: { finished in
                                                self.animateHideCard(at: firstIndex, self.cardButtons[firstIndex])
                                                self.animateHideCard(at: secondIndex, self.cardButtons[secondIndex])

                                                self.flipCompleted = true
                                            }
                                        )
                                    } else {
                                        self.flipCompleted = true
                                    }
                                } else {
                                    // 4 - count number of face up cards
                                    #if DEBUG
                                    print("count number of face up cards 4")
                                    #endif
                                    let faceUpCards = self.game.cards.indices.filter { self.game.cards[$0].isFaceUp }

                                    if faceUpCards.count == 2 {
                                        // 5 - there are two face up cards
                                        #if DEBUG
                                        print("there are two face up cards 5\n")
                                        #endif
                                        //
                                        // Delay flipping cards back over by wrapping UIView.transition in a UIView.animate with a delay paramater.
                                        // Putting a CGAffineTransform in the animations allows the 'delay' to work (it can't be empty).
                                        // I reset the button.transform back to its default within setupButtonsDefaults()
                                        //
                                        UIView.animate(
                                            withDuration: 0.0,
                                            delay: 0.8,
                                            options: [],
                                            animations: {
                                                // hack to make 'delay' work
                                                button.transform = CGAffineTransform(scaleX: 1.00000001, y: 1.00)
                                            },
                                            completion: { finished in
                                                self.cardButtons[faceUpCards[0]].setTitle("", for: .normal)
                                                self.cardButtons[faceUpCards[0]].backgroundColor = self.theme?.faceDownColor

                                                UIView.transition(
                                                    with: self.cardButtons[faceUpCards[0]],
                                                    duration: 0.5,
                                                    options: [.transitionFlipFromRight, .curveEaseInOut],
                                                    animations: nil,
                                                    completion: { finished in
                                                        // update model so cards are now back to being face down
                                                        self.game.cards[faceUpCards[0]].isFaceUp = false
                                                    }
                                                )

                                                self.cardButtons[faceUpCards[1]].setTitle("", for: .normal)
                                                self.cardButtons[faceUpCards[1]].backgroundColor = self.theme?.faceDownColor

                                                UIView.transition(
                                                    with: self.cardButtons[faceUpCards[1]],
                                                    duration: 0.5,
                                                    options: [.transitionFlipFromRight, .curveEaseInOut],
                                                    animations: nil,
                                                    completion: { finished in
                                                        // update model so cards are now back to being face down
                                                        self.game.cards[faceUpCards[1]].isFaceUp = false

                                                        self.flipCompleted = true
                                                    }
                                                )
                                            }
                                        )
                                    }
                                }
                            }
                        )
                    }
                )
            }
        )
    }

//    fileprivate func animateFlippingCardDown(at cardIndex: Int, _ button: UIButton, extraDelay: Double = 0.0) {
//        if self.game.cards[cardIndex].isFaceUp {
//            button.setTitle("", for: .normal)
//            button.backgroundColor = theme?.faceDownColor
//
//            UIView.transition(
//                with: button,
//                duration: 0.5,
//                options: [.transitionFlipFromRight, .curveEaseInOut],
//                animations: nil,
//                completion: { finished in
//                    // update model so cards are now back to being face down
//                    self.game.cards[cardIndex].isFaceUp = false
//                }
//            )
//        }
//    }

    fileprivate func animateHideCard(at cardIndex: Int, _ button: UIButton) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0.0,
            options: [.curveEaseIn],
            animations: { button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1) },
            completion: { finished in
                button.alpha = 0.0
                button.isOpaque = false

                // update model so cards are not face up
                self.game.cards[cardIndex].isFaceUp = false

                if self.gameOver.isHidden && self.game.areAllCardsMatched() {
                    // make game over label visible
                    self.gameOver.isHidden = false

                    // zoom out gameOver label 4X
                    UIView.animate(
                        withDuration: 2.0,
                        delay: 0.0,
                        usingSpringWithDamping: 0.4,
                        initialSpringVelocity: 0.4,
                        animations: {
                            // zoom out and rotate gameOver label to normal size
                            let scale = CGAffineTransform(scaleX: 1, y: 1)
                            let rotationAngle = CGAffineTransform(rotationAngle: 0.0)

                            let transform = scale.concatenating(rotationAngle)

                            self.gameOver.transform = transform
                        }
                    )
                }
            }
        )
    }

    private func areAllCardsMatched() -> Bool {
        for card in game.cards {
            if !card.isMatched {
                return false
            }
        }

        return true
    }
    
    private func emoji(for card: Card) -> String {
        if emoji[card] == nil && emojiChoices.count > 0 {
            let offset = emojiChoices.count.random
            let randomStringIndex = emojiChoices.index(emojiChoices.startIndex, offsetBy: offset)

            // get random emoji character and then remove it from string to prevent duplication
            emoji[card] = String(emojiChoices.remove(at: randomStringIndex))
        }

        if emoji[card] == nil {
            return "?"
        } else {
            return emoji[card]!
        }
//        return emoji[card] ?? "?"
    }

    func delayWithSeconds(_ seconds: TimeInterval, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { completion() }
    }
}

extension UIView {
    func rotate360Degrees(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(.pi * 2.0)
        rotateAnimation.duration = duration

        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = (delegate as! CAAnimationDelegate)
        }
        self.layer.add(rotateAnimation, forKey: nil)
    }
}

//extension UIView {
//    func shadow(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
//        let shadowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
//        shadowAnimation.fromValue = self.layer.shadowOpacity
//        shadowAnimation.toValue = 0.0
//        shadowAnimation.duration = 1.0
//
//        if let delegate: AnyObject = completionDelegate {
//            shadowAnimation.delegate = (delegate as! CAAnimationDelegate)
//        }
//
//        self.layer.add(animation, forKey: shadowAnimation.keyPath)
//        self.layer.shadowOpacity = 0.0
//    }
//}

extension UIColor {
    func lighter(by percentage: CGFloat=30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat=30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat=30.0) -> UIColor? {
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0;

        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)) {
            return UIColor(red:   min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue:  min(b + percentage/100, 1.0),
                           alpha: a)
        } else {
            return nil
        }
    }
}

extension UIButton {
    func copy() throws -> UIButton? {
        let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIButton
    }
}

/// UIButton extension which enables the caller to duplicate a UIButton
//extension UIButton {
//
//    /// Creates a duplicate of the terget UIButton
//    /// The caller specified the UIControlEvent types to copy across to the duplicate
//    ///
//    /// - Parameter controlEvents: UIControlEvent types to copy
//    /// - Returns: A UIButton duplicate of the original button
//    func duplicate(forControlEvents controlEvents: [UIControl.Event]) -> UIButton? {
//
//        // Attempt to duplicate button by archiving and unarchiving the original UIButton
//        let archivedButton = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
//        guard let buttonDuplicate = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(archivedButton!) else { return nil }
//
//        // Copy targets and associated actions
//        self.allTargets.forEach { target in
//
//            controlEvents.forEach { controlEvent in
//
//                self.actions(forTarget: target, forControlEvent: controlEvent)?.forEach { action in
//                    buttonDuplicate.addTarget(target, action: Selector(action), for: controlEvent)
//                }
//            }
//        }
//
//        return buttonDuplicate
//    }
//}








