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

    var gcEnabled = false // Check if the user has Game Center enabled
    var gcDefaultLeaderboardIdentifier = String() // Check the default leaderboardID
    let gcLeaderboardIdentifier = "com.mretondo.EmojiMatch"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Call the GC authentication controller
        authenticateLocalPlayer()
    }

    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            //            if ViewController != nil {
            //                // 1. Show login if player is not logged in
            //                self.present(ViewController!, animated: true, completion: nil)
            //            } else if localPlayer.isAuthenticated {

            if localPlayer.isAuthenticated {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true

                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier() { leaderboardIdentifer, error in
                    if let error = error {
                        #if DEBUG
                        print(error)
                        #endif
                    } else {
                        self.gcDefaultLeaderboardIdentifier = leaderboardIdentifer!
                    }
                }
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if var prompt = themeHeading.prompt, let appendIndex = themeHeading.prompt?.endIndex(of: ": ") {
            prompt = String(prompt.prefix(upTo: appendIndex))

            if let lowestFlips = AppDelegate.lowestFlips {
                prompt.append("\(lowestFlips) Flips")
            }

            themeHeading.prompt = prompt
        }

        themeHeading.rightBarButtonItem?.isHidden = !self.gcEnabled
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
