//
//  EmojiMatchLeaderboardTableViewController.swift
//  Match Emojis
//
//  Created by Mike Retondo on 2/15/20.
//

import Foundation
import UIKit
import GameKit

class EmojiMatchLeaderboardTableViewController: UIViewController, GKGameCenterControllerDelegate
{
    @IBOutlet weak var themeHeading: UINavigationItem!
    @IBOutlet weak var leaderboardStackView: UIStackView!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var addScoreButton: UIButton!

    var gcEnabled = false // Check if the user has Game Center enabled
    var gcDefaultLeaderboardIdentifier = String() // Check the default leaderboardID
    let gcLeaderboardIdentifier = "com.mretondo.EmojiMatch"

    let lowestScorePosible = 20

    var bestScoreFromGC: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Call the GC authentication controller
        authenticateLocalPlayer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updatePrompt()

        // give leaderboardStackView a background color as wide as the safeAreaView
        pinBackgroundView(backgroundView,
                          toStackView: leaderboardStackView,
                          leading: safeAreaView.leadingAnchor,
                          trailing: safeAreaView.trailingAnchor,
                          top: leaderboardStackView.topAnchor,
                          bottom: leaderboardStackView.bottomAnchor
        )

        themeHeading.rightBarButtonItem?.isHidden = !self.gcEnabled
    }

    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local

        // this is completion block
        localPlayer.authenticateHandler = { ViewController, error -> Void in
            if ViewController != nil {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if localPlayer.isAuthenticated {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true

                // Get the default leaderboard ID - updated in completion block
                localPlayer.loadDefaultLeaderboardIdentifier() { leaderboardIdentifer, error in
                    if let error = error {
                        #if DEBUG
                        print("authenticateLocalPlayer() localPlayer.loadDefaultLeaderboardIdentifier(): \(error)")
                        #endif
                    } else {
                        // get current best score - updated in completion block
                        self.updateLowestFlipsFromLeaderboard()
                    }
                }

                self.leaderboardButton.isEnabled = true
                self.addScoreButton.isEnabled = true
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false

                self.leaderboardButton.isEnabled = false
                self.addScoreButton.isEnabled = false

                #if DEBUG
                print("Local player could not be authenticated!")
                if let error = error {
                    print(error.localizedDescription)
                }
                #endif
            }

            //self.themeHeading.rightBarButtonItem?.isHidden = !self.gcEnabled
        }
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }

    @IBAction func checkGCLeaderboard(_ sender: Any) {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = gcLeaderboardIdentifier

        present(gcVC, animated: true, completion: nil)
    }

    @IBAction func addScoreAndSubmitToGC(_ sender: Any) {
        if let lowestFlips = AppDelegate.lowestFlips {
            // get current best score
            let bestScore = GKScore(leaderboardIdentifier: gcLeaderboardIdentifier)

            // add score only if its the players lowest score
            if bestScore.value == 0 || lowestFlips < bestScore.value {
                // set new best score
                bestScore.value = Int64(lowestFlips)

                // Submit new best score to GC leaderboard
                GKScore.report([bestScore]) { error in
                    var title: String
                    var message: String

                    if error == nil {
                        title = "Success"
                        message = "Your low score was added to the Leaderboard."
                    } else {
                        title = "The low score was unable to be added to the Leaderboard"
                        message = "error!.localizedDescription"
                    }

                    self.showOkAlert(title: title, message: message)
                }
            }
        }
    }

    /// shows Alert with OK button
    func showOkAlert(title: String, message: String) {
        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Create the actions
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { UIAlertAction in
            NSLog("OK Pressed")
        }

        // Add the actions
        alertController.addAction(okAction)

        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }

    /// shows Alert with OK and Cancel button
    /// returns 0=OK 1=Cancel
    func showOkCancelAlert(title: String, message: String) -> Int {
        var buttonPressed: Int = 0 // Default OK button

        // Create the alert controller
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Create the actions
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { UIAlertAction in
            NSLog("OK Pressed")
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { UIAlertAction in
            buttonPressed = 1
            NSLog("Cancel Pressed")
        }

        // Add the actions
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)

        // Present the controller
        self.present(alertController, animated: true, completion: nil)

        return buttonPressed
    }

    /// if user deleted there local data this will try to update it with the score from there Leaderboard score
    /// gets the score from GC in a completion block
    func updateLowestFlipsFromLeaderboard() {
        if GKLocalPlayer.local.isAuthenticated {
            // Initialize the leaderboard for the current local player
            let gkLeaderboard = GKLeaderboard(players: [GKLocalPlayer.local])
            gkLeaderboard.identifier = gcLeaderboardIdentifier
            gkLeaderboard.timeScope = GKLeaderboard.TimeScope.allTime

            // Get best score in Game Center if it exists
            // Scores are reported in the Closure
            gkLeaderboard.loadScores() { (scores, error) -> Void in
                if error != nil {
                    #if DEBUG
                    print("updateLowestFlipsFromLeaderboard() - gkLeaderboard.loadScores() - " + error.debugDescription)
                    #endif
                } else {
                    // are there scores available
                    if let scores = scores, scores.count > 0 {
                        // convert Int64 to Int
                        let currentScore = Int(truncatingIfNeeded: scores[0].value)

                        updateLowestFlips(with: currentScore)

                        do {
                            // save score to Core Data
                            try AppDelegate.viewContext.save()

                            self.updatePrompt()

                            #if DEBUG
                            print("Best score from Game Center: \(currentScore)")
                            #endif
                        }
                        catch {
                            print("updateLowestFlipsFromLeaderboard() - Couldn't save AppDelegate.viewContext")
                        }
                    }
                }
            }
        }

        /// if user deleted there local data this will try to update it with the score from the Leaderboard
        func updateLowestFlips(with score: Int) {
            if score > 0 {
                if let lowestFlips = AppDelegate.lowestFlips {
                    if score < lowestFlips {
                        AppDelegate.lowestFlips = score
                    }
                } else {
                    AppDelegate.lowestFlips = score
                }
            }
        }
    }

    /// update the heading prompt flip count with the lower of Leaderboard value or
    fileprivate func updatePrompt() {
        if var prompt = themeHeading.prompt, let appendIndex = themeHeading.prompt?.endIndex(of: ": ") {
            prompt = String(prompt.prefix(upTo: appendIndex))

            if let lowestFlips = AppDelegate.lowestFlips {
                prompt.append("\(lowestFlips) Flips")
            }

            themeHeading.prompt = prompt
        }
    }

    @IBOutlet var safeAreaView: UIView!

    /// backgroundView gives UIStackView a background color since UIStackView does NO rendering
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .groupTableViewBackground
        return view
    }()

    private func pinBackgroundView(_ backgroundView: UIView,
                                   toStackView view: UIStackView,
                                   leading: NSLayoutXAxisAnchor,
                                   trailing: NSLayoutXAxisAnchor,
                                   top: NSLayoutYAxisAnchor,
                                   bottom: NSLayoutYAxisAnchor) {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(backgroundView, at: 0)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leading),
            backgroundView.trailingAnchor.constraint(equalTo: trailing),
            backgroundView.topAnchor.constraint(equalTo: top),
            backgroundView.bottomAnchor.constraint(equalTo: bottom)
        ])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension UIBarButtonItem {
    var isHidden: Bool {
        get {
            return !isEnabled && tintColor == .clear
        }
        set {
            tintColor = newValue ? .clear : nil
            isEnabled = !newValue
        }
    }
}
