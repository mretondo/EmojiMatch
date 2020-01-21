//
//  EmojiMatchViewController.swift
//

import UIKit
import Foundation
import CoreData

class EmojiMatchViewController: UIViewController
{
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer {
        didSet { updateViewFromModel(touchedCard: nil) }
    }

    // sets the current theme and get ready for new game
    var theme: (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)? {
        didSet {
            self.view.backgroundColor = theme?.backgroundColor
            emojiChoices = theme?.emojis ?? ""

            flipCount = 0

            updateViewFromModel(touchedCard: nil)
        }
    }

    private var emojiChoices = ""
    private var emoji: [Card : String] = [:]

	private lazy var game = EmojiMatch(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
    private(set) var flipCount = 0 { didSet { updateFlipCountLabel() } }

    private var savedTitleAttributes: [ NSAttributedString.Key : Any ] = [:]

    private var flipCompleted = true

//    private var startTime = 0

    @IBOutlet private weak var flipCountLabel: UILabel! { didSet { updateFlipCountLabel() } }
    @IBOutlet private var cardButtons: [UIButton]!
    @IBOutlet private weak var gameOver: UILabel!

    @IBAction private func touchCard(_ sender: UIButton) {
        // ignore touches after game is over
        guard self.gameOver.isHidden else { return }

        guard let cardNumber = cardButtons.firstIndex(of: sender) else {
            print("touchCard(_:) - choosen card was not in cardButtons")
            return
        }

        let card = game.cards[cardNumber]
        guard !card.isFaceUp else { return } // ignore touches on face up cards

        if flipCompleted {
            flipCompleted = false
//            startTime = currentTimeInMilliSeconds()
        } else {
            // async alows previous card flipping animation to
            // complete before starting animation of second card.
            DispatchQueue.main.async {
                self.touchCard(sender)
//                while true {
//                    self.touchCard(sender)
//                    break
//                    let currentTime = self.currentTimeInMilliSeconds()
//                    if self.startTime + 500 < currentTime {
//                        self.touchCard(sender)
//                        break
//                    }
//                }
            }

            return  // consume event - also prevents double flip of cards
        }


        // if card isMatched then it can't be pressed
        if !card.isMatched && !card.isFaceUp {
            flipCount += 1
            game.chooseCard(at: cardNumber)
            updateViewFromModel(touchedCard: cardNumber)
        }
    }

//    func currentTimeInMilliSeconds() -> Int
//    {
//        let currentDate = Date()
//        let since1970 = currentDate.timeIntervalSince1970
//        return Int(since1970 * 1000)
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set view title to the theme's name
        title = theme?.name

        setButtonsFontSize()

        // zoom in gameOver label 4X
        let scale = CGAffineTransform(scaleX: 0.25, y: 0.25)
        // rotate label upsidedown
        let rotationAngle = CGAffineTransform(rotationAngle: .pi)

        UIView.animate(withDuration: 0.0) {
            self.gameOver.transform = scale.concatenating(rotationAngle)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // save all title text attributes so we can restore them when view disappears
        if let navigationBar = navigationController?.navigationBar {
            savedTitleAttributes = navigationBar.titleTextAttributes!

            // modify only the color and leave the rest alone
            var attributes = savedTitleAttributes

            // change the title text color for Christmas and Halloween
            if title == "Christmas" {
                attributes[.foregroundColor] = UIColor.red
                navigationBar.titleTextAttributes = attributes
            } else if title == "Halloween" {
                attributes[.foregroundColor] = UIColor.orange
                navigationBar.titleTextAttributes = attributes
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if areAllCardsMatched() {
            AppDelegate.lowestFlips = flipCount
            try? AppDelegate.viewContext.save()
        }

        // reset tableview title to black
        if let navigationBar = navigationController?.navigationBar {
            var attributes = savedTitleAttributes
            attributes[.foregroundColor] = UIColor.black
            navigationBar.titleTextAttributes = attributes
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setButtonsFontSize()
    }

    private func updateFlipCountLabel() {
        if let theme = theme {
            var attributes: [ NSAttributedString.Key : Any ] = [:]

            if theme.backgroundColor == #colorLiteral(red: 0, green: 0.2784313725, blue: 0.1529411765, alpha: 1) /* dark green for Christmas */ {
                attributes = [ .foregroundColor : theme.faceDownColor as Any ]
            } else if theme.backgroundColor == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) /* black for Holloween */ {
                attributes = [ .foregroundColor : theme.faceDownColor as Any ]
            } else {
                attributes = [ .strokeWidth: 2.0, .strokeColor: theme.faceDownColor ]
            }

            let attributedString = NSAttributedString(string: "Flips: \(flipCount)", attributes: attributes)

            flipCountLabel.attributedText = attributedString
        }
    }

    private func setButtonsFontSize() {
        if cardButtons != nil {
            for index in cardButtons.indices {
                let button = cardButtons[index]
                
                if var font = button.titleLabel?.font {
                    let defaultFontSize: CGFloat = 46.0

                    let deviceType = "\(UIDevice().type)"
                    if  deviceType.starts(with: "iPhone3") ||
                        deviceType.starts(with: "iPhone4") ||
                        deviceType.starts(with: "iPhone5") ||
                        deviceType.starts(with: "iPhone6") {
                        if UIDevice.current.orientation.isLandscape {
                            font = font.withSize(defaultFontSize - 14)
                        } else {
                            font = font.withSize(defaultFontSize)
                        }
                    } else {
                        if UIDevice.current.orientation.isLandscape {
                            font = font.withSize(defaultFontSize - 8)
                        } else {
                            font = font.withSize(defaultFontSize)
                        }
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
              
                if touchedCard != nil && card.isFaceUp {
                    if touchedCard == index {
                        // card has been tapped and needs to flip up
                        //print("\nStart \(flipCompleted)")

                        animateFlippingCardUp(card, button)

                        //print("End \(flipCompleted)\n")
                    } else {
                        // card is face up so the emoji
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

    private func sleep(_ seconds: Double) {
        let integerPart = seconds.integerPart() * 1_000_000 // convert to micro seconds
        let fractionalPart = seconds.fractionalPart(toNumberOfPlaces: 3) * 1_000 // convert to micro seconds
        let s = integerPart + fractionalPart

        usleep(useconds_t(s))
    }

    fileprivate func animateFlippingCardUp(_ card: Card, _ button: UIButton) {
        // 1 - lift the card
        //print("lift card 1")
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: { button.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) },
            completion: { finished in
//                if finished {
//                    print("Finished lift card 2")
//                } else {
//                    print("NOT - finished lift card 2")
//                }
                // after card is lifted then change the title and background - this will be the FlipTo side
                button.setTitle(self.emoji(for: card), for: .normal)
                button.backgroundColor = self.theme?.faceUpColor

                // 2 - flip the card
                //print("flip the card 3")
                UIView.transition(
                    with: button,
                    duration: 0.6,
                    options: [.transitionFlipFromLeft, .curveEaseInOut],
                    animations: nil,
                    completion: { finished in
//                        if finished {
//                            //print("finished flip the card 4")
//                        } else {
//                            //print("NOT - finished flip the card 4")
//                        }

                        // 3 - set card back down
                        //print("set card back down 5")
                        UIView.animate(
                            withDuration: 0.2,
                            delay: 0,
                            options: .curveEaseOut,
                            animations: { button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) },
                            completion: { finished in
//                                if finished {
//                                    //print("finished set card back down 6")
//                                } else {
//                                    //print("NOT - set card back down 6")
//                                }
                                // hide cards if matched
                                if card.isMatched {
                                    let indicesOfCards = self.game.indicesOfCard(card)

                                    if let firstIndex = indicesOfCards.0, let secondIndex = indicesOfCards.1 {
//                                        //print ("firstIndex = \(firstIndex)")
//                                        //print ("secondIndex = \(secondIndex)")

                                        UIView.animate(
                                            withDuration: 0.0,
                                            delay: 0.3,
                                            options: [.curveLinear],
                                            animations: {
                                                self.cardButtons[firstIndex].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//                                                //print ("Hide zoom card - \(self.cardButtons[firstIndex])")
                                                self.cardButtons[secondIndex].transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//                                                //print ("Hide zoom matchingCard - \(self.cardButtons[secondIndex])")
                                            },
                                            completion: { finished in
                                                self.animateHideCard(at: firstIndex, self.cardButtons[firstIndex])
//                                                //print ("Hide card 0 - \(self.cardButtons[firstIndex])")
                                                self.animateHideCard(at: secondIndex, self.cardButtons[secondIndex])
//                                                //print ("Hide card 1 - \(self.cardButtons[secondIndex])")

                                                self.flipCompleted = true
                                            }
                                        )
                                    } else {
                                        self.flipCompleted = true
                                    }
                                } else {
                                    let faceUpCards = self.game.cards.indices.filter { self.game.cards[$0].isFaceUp }

                                    if faceUpCards.count == 2 {
                                        //print ("FlippingCardDown 1 - \(faceUpCards[0])")
                                        //print ("FlippingCardDown 2 - \(faceUpCards[1])")
                                        //print ("faceUpCards.count == 2")

                                        UIView.animate(
                                            withDuration: 0.0,
                                            delay: 0.8,
                                            options: [],
                                            animations: { button.transform = CGAffineTransform(scaleX: 1.01, y: 1.00) },
                                            completion: { finished in
//                                                if finished {
//                                                    //print("finished FlippingCardDown 7")
//                                                } else {
//                                                    //print("NOT - FlippingCardDown 7")
//                                                }
                                                self.animateFlippingCardDown(at: faceUpCards[0], self.cardButtons[faceUpCards[0]])
//                                                //print ("FlippingCardDown 0 - \(self.cardButtons[faceUpCards[0]])")
                                                self.animateFlippingCardDown(at: faceUpCards[1], self.cardButtons[faceUpCards[1]])
//                                                //print ("FlippingCardDown 1 - \(self.cardButtons[faceUpCards[1]])")

                                                self.flipCompleted = true
                                            }
                                        )
                                    } else {
                                        //print ("faceUpCards.count != 2")
                                        self.flipCompleted = true
                                    }
                                }
                            }
                        )
                    }
                )
            }
        )
        //print("done")
    }

    fileprivate func animateFlippingCardDown(at cardIndex: Int, _ button: UIButton, extraDelay: Double = 0.0) {
        if self.game.cards[cardIndex].isFaceUp {
            button.setTitle("", for: .normal)
            button.backgroundColor = self.theme?.faceDownColor

            UIView.transition(
                with: button,
                duration: 0.5,
                options: [.transitionFlipFromRight, .curveEaseInOut],
                animations: nil,
                completion: { finished in
                    // update model so cards are now back to being face down
                    self.game.cards[cardIndex].isFaceUp = false
                }
            )
        }
    }

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

        return emoji[card] ?? "?"
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

        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red:   min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue:  min(b + percentage/100, 1.0),
                           alpha: a)
        } else {
            return nil
        }
    }
}









