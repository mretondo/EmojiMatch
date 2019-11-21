//
//  EmojiMatchViewController.swift
//

import UIKit
import Foundation

class EmojiMatchViewController: UIViewController
{
	private lazy var game = EmojiMatch(numberOfPairsOfCards: (cardButtons.count + 1) / 2)
    private(set) var flipCount = 0 { didSet { updateFlipCountLabel() } }

    @IBOutlet private weak var flipCountLabel: UILabel! { didSet { updateFlipCountLabel() } }

    @IBOutlet private var cardButtons: [UIButton]!

    @IBOutlet private weak var gameOver: UILabel!

    private func updateFlipCountLabel() {
        var attributes: [ NSAttributedString.Key: Any ] = [:]

        if backgroundColor == #colorLiteral(red: 0, green: 0.2784313725, blue: 0.1529411765, alpha: 1)  {
            attributes = [ .foregroundColor: faceDownColor ]
        } else if backgroundColor == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            attributes = [ .foregroundColor: faceDownColor ]
        } else {
            attributes = [ .strokeWidth: 2.0, .strokeColor: faceDownColor ]
        }

        let attributedString = NSAttributedString(string: "Flips: \(flipCount)", attributes: attributes)

        flipCountLabel.attributedText = attributedString
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setButtonsFontSize()

        // zoom in gameOver label 4X
        let scale = CGAffineTransform(scaleX: 0.25, y: 0.25)
        // rotate label upsidedown
        let rotationAngle = CGAffineTransform(rotationAngle: .pi)

        UIView.animate(withDuration: 0.0) {
            self.gameOver.transform = scale.concatenating(rotationAngle)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if areAllCardsMatched() {
            AppDelegate.lowestFlips = flipCount
            try? AppDelegate.viewContext.save()
        }
    }
    
	@IBAction private func touchCard(_ sender: UIButton) {
        if let cardNumber = cardButtons.firstIndex(of: sender) {
            let card = game.cards[cardNumber]

            // if card isMatched then it can't be pressed
            if !card.isMatched && !card.isFaceUp {
                flipCount += 1
                game.chooseCard(at: cardNumber)
                updateViewFromModel(touchedCard: cardNumber)
            }
        } else {
            print("choosen card was not in cardButtons")
        }
	}
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setButtonsFontSize()
    }
    
    private func setButtonsFontSize() {
        if cardButtons != nil {
            for index in cardButtons.indices {
                let button = cardButtons[index]
                
                if var font = button.titleLabel?.font {
                    if UIDevice.current.orientation.isLandscape {
                        font = font.withSize(42)
                    } else {
                        font = font.withSize(46)
                    }
                    
                    button.titleLabel?.font = font
                }
            }
        }
    }

    private func updateViewFromModel(touchedCard: Int?) {
        if cardButtons != nil {
            for index in cardButtons.indices {
                let button = cardButtons[index]
                let card = game.cards[index]
              
                if touchedCard != nil && card.isFaceUp {
                    if touchedCard == index {
                        animateFlippingCard(card, button)
                    } else {
                        button.setTitle(emoji(for: card), for: .normal)
                        button.backgroundColor = faceUpColor
                    }
                } else {
                    // card is face down so no emoji to show
                    button.setTitle("", for: .normal)
                    // if card isMatched then it's effectively hidden i.e transparent
                    button.backgroundColor = card.isMatched ? #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 0) : faceDownColor
                }
            }
        }
	}

    fileprivate func animateFlippingCard(_ card: Card, _ button: UIButton) {
        //
        // 1 - lift the card
        //
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.curveEaseIn],
                       animations: { button.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) },
                       completion: { finished in
                            // after card is lifted then change the title and background - this will be the FlipTo side
                            button.setTitle(self.emoji(for: card), for: .normal)
                            button.backgroundColor = self.faceUpColor

                            //
                            // 2 - flip the card
                            //
                            UIView.transition(with: button,
                                              duration: 0.6,
                                              options: [.transitionFlipFromLeft, .curveEaseInOut],
                                              animations: nil,
                                              completion: { finished in
                                                    //
                                                    // 3 - set card back down
                                                    //
                                                    UIView.animate(withDuration: 0.2,
                                                                   delay: 0,
                                                                   options: .curveEaseOut,
                                                                   animations: { button.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) },
                                                                   completion: { finished in
                                                                        self.hidePairOfFaceUpCards(afterTimeInterval: 0.6)

                                                                        //
                                                                        // 5 - if the game is over then zoom out and rotate "Game Over"
                                                                        //
                                                                        if self.areAllCardsMatched() {
                                                                            self.gameOver.isHidden = false

                                                                            // zoom out gameOver label 4X
                                                                            UIView.animate(withDuration: 2.0,
                                                                                           delay: 0.0,
                                                                                           usingSpringWithDamping: 0.4,
                                                                                           initialSpringVelocity: 0.4,
                                                                                           animations: {
                                                                                               // zoom out and rotate gameOver label to normal size
                                                                                               let scale = CGAffineTransform(scaleX: 1, y: 1)
                                                                                               let rotationAngle = CGAffineTransform(rotationAngle: 0.0)

                                                                                               let transform = scale.concatenating(rotationAngle)

                                                                                               self.gameOver.transform = transform
                                                                                           })
                                                                        }
                                                                   })
                                              })
                        })
    }

    fileprivate func hidePairOfFaceUpCards(afterTimeInterval deley: TimeInterval) {
        var upButtons = [UIButton]()
        var faceUpIndexs: [Array<Any>.Index] = []

        for i in cardButtons.indices {
            if game.cards[i].isFaceUp {
                upButtons.append(cardButtons[i])
                faceUpIndexs.append(i)
            }
        }

        if upButtons.count == 2 {
            if game.cards[faceUpIndexs[0]].isMatched && game.cards[faceUpIndexs[1]].isMatched {
//                cardButtons.forEach() {
//                    $0.layer.zPosition = 0
//                }
//
//                upButtons[0].layer.zPosition = 1
//                upButtons[1].layer.zPosition = 2

                UIView.animate(withDuration: 0.4,
                               delay: deley,
                               options: [.curveEaseInOut],
                               animations: {
                                    upButtons[0].transform = CGAffineTransform(scaleX: 3.00, y: 3.00)
                                    upButtons[1].transform = CGAffineTransform(scaleX: 3.00, y: 3.00)
                               },
                               completion: { finished in
                                    UIView.animate(withDuration: 0.5,
                                                   delay: 0,
                                                   options: [.curveEaseIn],
                                                   animations: {
                                                        upButtons[0].transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                                                        upButtons[1].transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                                                    },
                                                   completion: { finished in
                                                        upButtons[0].isOpaque = false
                                                        upButtons[1].isOpaque = false
                                                        upButtons[0].alpha = 0.0
                                                        upButtons[1].alpha = 0.0
                                                    } )
                                } )
            } else {
                Thread.sleep(forTimeInterval: deley)
            }

            // both face up cards are now down and maybe invisable if they matched
            game.cards[faceUpIndexs[0]].isFaceUp = false
            game.cards[faceUpIndexs[1]].isFaceUp = false

            updateViewFromModel(touchedCard: nil)
        }
    }

    private func areAllCardsMatched() -> Bool {
        for index in cardButtons.indices {
            let card = game.cards[index]

            if !card.isMatched {
                return false
            }
        }

        return true
    }
    
    // sets the current theme and get ready for new game
    var theme: (name: String, emojis: String, backgroundColor: UIColor, faceDownColor: UIColor, faceUpColor: UIColor)? {
        didSet {
            themeName = theme?.name ?? ""
            emojiChoices = theme?.emojis ?? ""
            backgroundColor = theme?.backgroundColor ?? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            faceDownColor = theme?.faceDownColor ?? #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
            faceUpColor = theme?.faceUpColor ?? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            self.view.backgroundColor = backgroundColor
            
            emoji = [:]
            flipCount = 0
            
            updateViewFromModel(touchedCard: nil)
        }
    }

    private var themeName = ""
    private var emojiChoices = ""
    private var emoji = [Card: String]()
    private var backgroundColor = UIColor.clear
    private var faceDownColor = UIColor.clear
    private var faceUpColor = UIColor.clear
	
    private func emoji(for card: Card) -> String {
        if emoji[card] == nil, emojiChoices.count > 0 {
            let offset = emojiChoices.count.random
            let randomStringIndex = emojiChoices.index(emojiChoices.startIndex, offsetBy: offset)
            
            // get random emoji character and then remove it from string to prevent duplication
            emoji[card] = String(emojiChoices.remove(at: randomStringIndex))
        }
        return emoji[card] ?? "?"
    }
}

extension Int {
    var random: Int {
        if self > 0 {
            return Int.random(in: 0 ..< self)
        }
        else if self < 0 {
            // get random number in positive range then negate it
            return -Int.random(in: 0 ..< abs(self))
        }
        else {
            // no emoji to randomise
            return 0
        }
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

extension UIView {
    func shadow(duration: CFTimeInterval = 1.0, completionDelegate: AnyObject? = nil) {
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
    }
}

extension UIColor {

    func lighter(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        } else {
            return nil
        }
    }
}










