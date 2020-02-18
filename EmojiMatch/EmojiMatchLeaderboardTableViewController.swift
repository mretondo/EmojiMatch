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
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var addScoreButton: UIButton!

    var gcEnabled = false // Check if the user has Game Center enabled
    var gcDefaultLeaderboardIdentifier = String() // Check the default leaderboardID
    let gcLeaderboardIdentifier = "com.mretondo.EmojiMatch"

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
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            //            if ViewController != nil {
            //                // 1. Show login if player is not logged in
            //                self.present(ViewController!, animated: true, completion: nil)
            //            } else if localPlayer.isAuthenticated {

            if localPlayer.isAuthenticated {
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

                self.showButton.isEnabled = true
                self.addScoreButton.isEnabled = true
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false

                self.showButton.isEnabled = false
                self.addScoreButton.isEnabled = false

                #if DEBUG
                print("Local player could not be authenticated!")
                if let error = error {
                    print(error)
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
                    #if DEBUG
                    if error != nil {
                        print(error!.localizedDescription)
                    } else {
                        print("Lowest Flip Count Score submitted to your Leaderboard!")
                    }
                    #endif
                }
            }
        }
    }

    /// if user deleted there local data this will try to update it with the score from there Leaderboard score
    /// gets the score from GC in a completion block
    func updateLowestFlipsFromLeaderboard() {
        if GKLocalPlayer.local.isAuthenticated {
            // Initialize the leaderboard for the current local player
            let gkLeaderboard = GKLeaderboard(players: [GKLocalPlayer.local])
            gkLeaderboard.identifier = gcLeaderboardIdentifier
            gkLeaderboard.timeScope = GKLeaderboard.TimeScope.allTime

            // Load the scores in a completion block
            gkLeaderboard.loadScores() { (scores, error) -> Void in
                // Get current score
                if error == nil {
                    if scores!.count > 0 {
                        let currentScore = Int(truncatingIfNeeded: scores![0].value)

                        updateLowestFlips(with: currentScore)

                        do {
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
