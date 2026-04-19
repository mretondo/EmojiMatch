//
//  CardsViewController.swift
//

import UIKit
import Foundation
import CoreData

@MainActor
class CardsViewController: UIViewController
{
    @IBOutlet private weak var scoreLabel: UILabel! { didSet { updateScoreLabel() } }
    @IBOutlet private var cardButtons: [UIButton]!
    @IBOutlet private weak var gameOver: UILabel!

//    var container: NSPersistentContainer? = AppEnvironment.shared.coreDataStack.persistentContainer {
//        didSet { updateViewFromModel(touchedCard: nil) }
//    }

//    var coreDataStack: CoreDataStack?  {
//        didSet { updateViewFromModel(touchedCard: nil) }
//    }

    // sets the current theme and get ready for new game
    var theme: (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)? {
        didSet {
            view.backgroundColor = theme?.backgroundColor
            emojiChoices = theme?.emojis ?? ""

            updateViewFromModel(touchedCard: nil)
        }
    }

    private(set) var score: Int64 = 0 { didSet { updateScoreLabel() } }
    private var secondCardFlipCompleted = false
    private var emojiChoices = ""
    private var emoji: [Card : String] = [:]
    private var seenCards: [Card : Bool] = [:]
    private lazy var game = EmojiMatchModel(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
    private var firstTouchedCardIndex: Int?

    @IBAction private func touchCard(_ sender: UIButton) {
        // ignore touches after game is over
        guard self.gameOver.isHidden else { return }

        guard let touchedCardIndex = cardButtons.firstIndex(of: sender) else {
            #if DEBUG
            print("touchCard(_:) - choosen card was not in cardButtons")
            #endif
            return
        }

        let touchedCard = game.cards[touchedCardIndex]
        guard !touchedCard.isFaceUp && !touchedCard.isTransitioningToFaceUp else { return } // ignore touches on Transitioning/face up cards

        if game.indicesOfTransitioningToFaceUpCardsAndFaceUpCards.count == 1 {
            self.view.isUserInteractionEnabled = false
        }

        // if two cards have not finished flipping back down then ignore new touched card
        if secondCardFlipCompleted {
            secondCardFlipCompleted = false
        }

        // if card isMatched then it can't be pressed
        if !touchedCard.isMatched {
            game.chooseCard(at: touchedCardIndex)

            let indicesOfFaceUpCards = game.indicesOfTransitioningToFaceUpCardsAndFaceUpCards

            if indicesOfFaceUpCards.count == 2 {
                // at this point touchedCardIndex is pointing to the second touched card

                updateScore(for: touchedCardIndex)

                if game.cards[touchedCardIndex].isMatched == false {
                    firstTouchedCardIndex = nil
                }

                game.cards[indicesOfFaceUpCards[0]].hasBeenSeen = true
                game.cards[indicesOfFaceUpCards[1]].hasBeenSeen = true
            } else {
                firstTouchedCardIndex = touchedCardIndex
            }
        }

        updateViewFromModel(touchedCard: touchedCardIndex)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set view title to the theme's name
        title = theme?.name

        setButtonsFontSize()

        setupNewGame()

        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitVerticalSizeClass.self]) { [weak self] (controller: UIViewController, previousTraitCollection: UITraitCollection) in
                guard let self = self else { return }
                updateScoreLabel()
                setButtonsFontSize()
            }
        }
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
        if title == "Christmas" || title == "Halloween", let theme = theme, let navigationBar = navigationController?.navigationBar {
            // change the titles text color for Christmas and Halloween
            navigationBar.largeTitleTextAttributes = [.foregroundColor : theme.faceDownColor]
            navigationBar.titleTextAttributes = [.foregroundColor : theme.faceDownColor]

            if #available(iOS 26.0, *) {
                // iOS 26.0+ behavior (if needed in the future)
            } else {
                //                    let appearance = UINavigationBarAppearance(idiom: .phone)
                //                    appearance.largeTitleTextAttributes = [.foregroundColor : theme.faceDownColor]
                //                    appearance.titleTextAttributes = [.foregroundColor : theme.faceDownColor]
                //
                //                    navigationItem.standardAppearance = appearance

                navigationBar.barStyle = .black // white text, I know, weird
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if areAllCardsMatched() {
            Task {
                await saveHighScore()
            }
        }

        // reset titles text to default color if changed in viewWillAppear
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.largeTitleTextAttributes = [:]
            navigationBar.titleTextAttributes = [:]

            if #available(iOS 26.0, *) {
                // iOS 26.0+ behavior (if needed in the future)
            } else {
                navigationController?.navigationBar.barStyle = .default
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setButtonsFontSize()
    }

    @IBAction func newGame(_ sender: UIBarButtonItem) {
        Task {
            if areAllCardsMatched() {
                await saveHighScore()
            }

            for index in cardButtons.indices {
                cardButtons[index].layer.removeAllAnimations()
            }

            // setup cards to scale to zero size so we can zoom cards back out
            for index in cardButtons.indices {
                cardButtons[index].transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                cardButtons[index].alpha = 0.0
                cardButtons[index].isOpaque = false
            }

            _ = await UIView.animate(withDuration: 0.6, delay: 0.2, options: [.curveEaseOut]) { [self] in
                setupNewGame()

                updateViewFromModel(touchedCard: nil)
            }
        }
    }

    fileprivate func setupGameOverLabel() {
        self.gameOver.isHidden = true

        // zoom in gameOver label 4X
        let scale = CGAffineTransform(scaleX: 0.25, y: 0.25)
        // rotate label upsidedown
        let rotationAngle = CGAffineTransform(rotationAngle: .pi)

        // Set transform directly since duration is 0.0
        self.gameOver.transform = scale.concatenating(rotationAngle)
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

    fileprivate func setupCardsDefaults() {
        // setup Cards to start of game defaults
        for index in cardButtons.indices {
            game.cards[index].hasBeenSeen = false
            game.cards[index].isTransitioningToFaceUp = false
            game.cards[index].isFaceUp = false
            game.cards[index].isMatched = false
        }
    }

    private func setupNewGame() {
        setupGameOverLabel()

        setupButtonsDefaults()

        setupCardsDefaults()

        score = 0
        secondCardFlipCompleted = false
        self.view.isUserInteractionEnabled = true
        emojiChoices = theme?.emojis ?? ""
        emoji = [:]
        seenCards = [:]
        game = EmojiMatchModel(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
        firstTouchedCardIndex = nil
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

    private func setButtonsFontSize() {
        if cardButtons != nil {
            for index in cardButtons.indices {
                let button = cardButtons[index]
                
                if var font = button.titleLabel?.font {
                    let defaultFontSize: Double = 46.0

                    if UIDevice.current.orientation.isLandscape {
                        font = font.withSize(defaultFontSize - 6)
                    } else {
                        font = font.withSize(defaultFontSize)
                    }

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

    private func updateScore(for touchedCardIndex: Int) {
        if game.cards[touchedCardIndex].isMatched {
            // Congradulations! you found matching cards and get 1 point
            score += 1
        } else {
            // we don't deduct points in ease mode
            if !AppEnvironment.shared.easyScoringMode {
                //
                // Deduct 2 point if you've seen first card's twin card
                // You should have remembered where the first cards' match was located
                //
                let twinCardIndex: Int = game.twinCardIndex(of: firstTouchedCardIndex!)!
                if game.hasCardBeenSeen(at: twinCardIndex) {
                    score -= 2
                } else {
                    // Deduct 1 point if you've seen the second card
                    // You should have known the second card wasn't a match
                    if game.hasCardBeenSeen(at: touchedCardIndex) {
                        score -= 1
                    }
                }
            }

            //
            // cap lowest score to -100
            //
            if score < LeaderboardTableViewController.lowestScorePossible {
                score = LeaderboardTableViewController.lowestScorePossible
            }
        }
    }

    fileprivate func hideCards(_ firstIndex: Int, _ secondIndex: Int) async {
        let scaleFinished = await UIView.animate(withDuration: 0.0, delay: 0.3, options: [.curveLinear]) {
            self.cardButtons[firstIndex].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.cardButtons[secondIndex].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        
        if scaleFinished {
            await hideCard(at: firstIndex, self.cardButtons[firstIndex])
            await hideCard(at: secondIndex, self.cardButtons[secondIndex])
            
            secondCardFlipCompleted = true
            view.isUserInteractionEnabled = true
        } else {
            #if DEBUG
            print("hideCards - scale didn't finished")
            #endif
        }
    }

    fileprivate func animateFlippingCardUp(_ card: Card, _ button: UIButton) {
        Task {
            let flipUpFinished = await runFlipUpAnimation(for: card, on: button)
            guard flipUpFinished else {
                #if DEBUG
                print("runFlipAnimation FAILD")
                #endif
                return
            }

            if let index = self.cardButtons.firstIndex(of: button) {
                self.game.cards[index].isTransitioningToFaceUp = false
                self.game.cards[index].isFaceUp = true
            }

            if card.isMatched {
                // hide cards if matched and check if game is over
                let indicesOfCards = game.indicesOfCard(card)

                if let firstIndex = indicesOfCards.0, let secondIndex = indicesOfCards.1 {
                    await hideCards(firstIndex, secondIndex)

                    if self.gameOver.isHidden && self.game.areAllCardsMatched() {
                        await showGameOver()
                    }
                } else {
                    secondCardFlipCompleted = true
                    view.isUserInteractionEnabled = true
                }
            } else {
                // Count number of face up cards
                let faceUpCards = self.game.cards.indices.filter { self.game.cards[$0].isFaceUp }
                
                if faceUpCards.count == 2 {
                    await flipBothCardsDown(faceUpCards: faceUpCards)
                }
            }
        }
    }

    //
    // ​MARK: - ​Animation ​Helpers
    //
    fileprivate func runFlipUpAnimation(for card: Card, on button: UIButton) async -> Bool {
        let liftFinished = await liftCardUp(button)
        guard liftFinished else {
            #if DEBUG
            print("liftCardUp FAILD")
            #endif
            return false
        }

        // after card is lifted then change the title and background - this will be the FlipTo side
        applyFlipToSide(for: card, on: button)

        let flipFinished = await flipCardOver(button)
        guard flipFinished else {
            #if DEBUG
            print("flipCardOver FAILD")
            #endif
            return false
        }

        let lowerFinished = await lowerCardDown(button)
        guard lowerFinished else {
            #if DEBUG
            print("lowerCardDown FAILD")
            #endif
            return false
        }

        return true
    }

    fileprivate func liftCardUp(_ button: UIButton) async -> Bool {
        return await UIView.animate(withDuration: 0.2, options: [.curveEaseIn]) {
            button.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }
    }

    fileprivate func flipCardOver(_ button: UIButton) async -> Bool {
        return await UIView.transition(with: button, duration: 0.6, options: [.transitionFlipFromLeft, .curveEaseInOut])
    }

    fileprivate func lowerCardDown(_ button: UIButton) async -> Bool {
        return await UIView.animate(withDuration: 0.2, options: .curveEaseOut) {
            button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }

    fileprivate func applyFlipToSide(for card: Card, on button: UIButton) {
        // after card is lifted then change the title and background - this will be the FlipTo side
        button.setTitle(self.emoji(for: card), for: .normal)
        button.backgroundColor = self.theme?.faceUpColor
    }

    fileprivate func showGameOver() async {
        self.gameOver.isHidden = false

        // zoom out gameOver label 4X
        let gameOverFinished = await UIView.animate(withDuration: 2.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.4) {
            // zoom out and rotate gameOver label to normal size
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            let rotationAngle = CGAffineTransform(rotationAngle: 0.0)

            let transform = scale.concatenating(rotationAngle)

            self.gameOver.transform = transform
        }

        if !gameOverFinished {
            #if DEBUG
            print("zoom out gameOver FAILED")
            #endif
        }
    }

    fileprivate func flipBothCardsDown(faceUpCards: [Int]) async {
        await self.delay(seconds: 0.8)

        self.cardButtons[faceUpCards[0]].setTitle("", for: .normal)
        self.cardButtons[faceUpCards[0]].backgroundColor = self.theme?.faceDownColor

        // Run both cards being flipped transitions concurrently using async let
        async let flip0 = UIView.transition(
            with: self.cardButtons[faceUpCards[0]],
            duration: 0.5,
            options: [.transitionFlipFromRight, .curveEaseInOut]
        )

        self.cardButtons[faceUpCards[1]].setTitle("", for: .normal)
        self.cardButtons[faceUpCards[1]].backgroundColor = self.theme?.faceDownColor

        async let flip1 = UIView.transition(
            with: self.cardButtons[faceUpCards[1]],
            duration: 0.5,
            options: [.transitionFlipFromRight, .curveEaseInOut]
        )

        // Wait for both flips to complete
        let (finished0, finished1) = await (flip0, flip1)

        // update model so cards are now back to being face down
        if finished0 {
            self.game.cards[faceUpCards[0]].isFaceUp = false
        } else {
            #if DEBUG
            print("flip0 FAILED")
            #endif
        }

        if finished1 {
            self.game.cards[faceUpCards[1]].isFaceUp = false

            self.secondCardFlipCompleted = true
            self.view.isUserInteractionEnabled = true
        } else {
            #if DEBUG
            print("flip1 FAILED")
            #endif
        }
    }

    fileprivate func hideCard(at cardIndex: Int, _ button: UIButton) async {
        let shrinkFinished = await UIView.animate(withDuration: 0.2, options: [.curveEaseIn]) {
            button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }
        guard shrinkFinished else {
            print("shrinkFinished FAILD")
            return
        }
        
        button.alpha = 0.0
        button.isOpaque = false
        
        // update model so card is not face up
        self.game.cards[cardIndex].isFaceUp = false
    }

    private func areAllCardsMatched() -> Bool {
        for card in game.cards {
            if !card.isMatched {
                return false
            }
        }

        return true
    }
    
    private func saveHighScore() async {
        AppDelegate.shared.highScore = score
        
        // Capture the managed object context reference on the main actor
        let moc = AppEnvironment.shared.coreDataStack.moc
        
        do {
            try await moc.perform {
                try moc.save()
            }
        } catch {
            #if DEBUG
            print("Failed to save high score: \(error)")
            #endif
        }
    }
    
    private func emoji(for card: Card) -> String {
        if emoji[card] == nil && emojiChoices.count > 0 {
            let offset = emojiChoices.count.random
            let randomStringIndex = emojiChoices.index(emojiChoices.startIndex, offsetBy: offset)

            // get random emoji character and then remove it from string to prevent duplication
            emoji[card] = String(emojiChoices.remove(at: randomStringIndex))
        }

        return emoji[card] ?? "?"
    }

    func delay(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

@MainActor
extension UIView {
    /// Performs an animation and returns when it completes using async/await
    static func animate(withDuration duration: TimeInterval, delay: TimeInterval = 0, options: UIView.AnimationOptions = [], animations: @escaping () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations) { finished in
                continuation.resume(returning: finished)
            }
        }
    }
    
    /// Performs a spring animation and returns when it completes using async/await
    static func animate(withDuration duration: TimeInterval, delay: TimeInterval = 0, usingSpringWithDamping dampingRatio: CGFloat, initialSpringVelocity velocity: CGFloat, options: UIView.AnimationOptions = [], animations: @escaping () -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: dampingRatio, initialSpringVelocity: velocity, options: options, animations: animations) { finished in
                continuation.resume(returning: finished)
            }
        }
    }
    
    /// Performs a transition animation and returns when it completes using async/await
    static func transition(with view: UIView, duration: TimeInterval, options: UIView.AnimationOptions = [], animations: (() -> Void)? = nil) async -> Bool {
        await withCheckedContinuation { continuation in
            UIView.transition(with: view, duration: duration, options: options, animations: animations) { finished in
                continuation.resume(returning: finished)
            }
        }
    }
    
    func rotate360Degrees(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = .pi * 2.0
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
    func lighter(by percentage: Double = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: Double = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: Double = 30.0) -> UIColor? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

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
        let archivedData = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIButton.self], from: archivedData) as? UIButton
    }
}

extension NSObject {
    func copyObject<T:NSObject>() throws -> T? {
        let archivedData = try NSKeyedArchiver.archivedData(withRootObject: T.self, requiringSecureCoding: false)
        return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [T.self], from: archivedData) as? T
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
















