//
//  LeaderboardTableViewController.swift
//  Match Emojis
//
//  Created by Mike Retondo on 2/15/20.
//

import Foundation
import UIKit
import GameKit
import MRUtils

class LeaderboardTableViewController: UIViewController, GKGameCenterControllerDelegate
{
    @IBOutlet weak var themeHeading: UINavigationItem!
    @IBOutlet weak var leaderboardStackView: UIStackView!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var addScoreButton: UIButton!

    public static let lowestScorePosible: Int64 = -100

    var gcEnabled = false // Check if the user has Game Center enabled
    var gcDefaultLeaderboardIdentifier = "com.mretondo.EmojiMatch2" // Check the default leaderboardID
    let gcLeaderboardIdentifier = "com.mretondo.EmojiMatch2"

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

                // Get the default leaderboard ID - updated in Completion block
                localPlayer.loadDefaultLeaderboardIdentifier() { leaderboardIdentifer, error in
                    if let error = error {
                        #if DEBUG
                        print("authenticateLocalPlayer() localPlayer.loadDefaultLeaderboardIdentifier(): \(error)")
                        #endif
                    } else {
                        // get current best score - updated in completion block
                        self.updateScoreFromLeaderboard()
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
        if let highestScore = AppDelegate.highScore {
            if GKLocalPlayer.local.isAuthenticated {
                // Initialize the leaderboard for the current local player
                let gkLeaderboard = GKLeaderboard(players: [GKLocalPlayer.local])
                gkLeaderboard.identifier = gcLeaderboardIdentifier
                gkLeaderboard.timeScope = GKLeaderboard.TimeScope.allTime

                // Get best score from the leaderboard if it exists
                // Scores are reported in the Closure
                gkLeaderboard.loadScores() { (scores, error) -> Void in
                    if error != nil {
                        #if DEBUG
                        print("updateScoreFromLeaderboard() - gkLeaderboard.loadScores() - " + error.debugDescription)
                        #endif
                    } else {
                        var title = ""
                        var message = ""
                        let score = GKScore(leaderboardIdentifier: self.gcLeaderboardIdentifier)

                        // set score to the current highest score
                        score.value = highestScore

                        // if a score already exits on the leader board compare to it
                        if let scores = scores, scores.count > 0 {
                            let leaderboardsHighestScore = Int(scores[0].value)

                            if leaderboardsHighestScore >= highestScore {
                                title = "Your leaderboard score is already the best."
                                message = ""
                                self.showOkAlert(title: title, message: message)

                                return
                            }
                        }

                        // Submit best score to GC leaderboard
                        GKScore.report([score]) { error in
                            if error == nil {
                                title = "Success"
                                message = "Your high score was added to the Leaderboard."
                            } else {
                                title = "The high score was unable to be added to the Leaderboard."
                                message = "error!.localizedDescription"
                            }

                            self.showOkAlert(title: title, message: message)
                        }
                    }
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

    /// If user deleted there local data this will try to update it with the score from there Leaderboard score
    /// Gets the score from GC in a completion block
    func updateScoreFromLeaderboard() {
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
                    print("updateScoreFromLeaderboard() - gkLeaderboard.loadScores() - " + error.debugDescription)
                    #endif
                } else {
                    // are there scores available
                    if let scores = scores, scores.count > 0 {
                        let currentScore = scores[0].value

                        updateHighestScore(with: currentScore)

                        do {
                            // save score to Core Data
                            try AppDelegate.viewContext.save()

                            self.updatePrompt()

                            #if DEBUG
                            print("Best score from Game Center: \(currentScore)")
                            #endif
                        }
                        catch {
                            print("updateScoreFromLeaderboard() - Couldn't save AppDelegate.viewContext")
                        }
                    }
                }
            }
        }

        /// if user deleted there local data this will try to update it with the score from the Leaderboard
        func updateHighestScore(with score: Int64) {
            if score >= LeaderboardTableViewController.lowestScorePosible {
                if let highestScore = AppDelegate.highScore {
                    if score > highestScore {
                        AppDelegate.highScore = score
                    }
                } else {
                    AppDelegate.highScore = score
                }
            }
        }
    }

    /// update the heading prompt high score
    fileprivate func updatePrompt() {
        if var prompt = themeHeading.prompt, let appendIndex = themeHeading.prompt?.endIndex(of: ": ") {
            prompt = String(prompt.prefix(upTo: appendIndex))

            if let highestScore = AppDelegate.highScore {
                prompt.append("\(highestScore)")
            }

            themeHeading.prompt = prompt
        }
    }

    @IBOutlet var safeAreaView: UIView!

    /// backgroundView gives UIStackView a background color since UIStackView does NO rendering
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
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
