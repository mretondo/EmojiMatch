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

class LeaderboardTableViewController: UIViewController, GKGameCenterControllerDelegate, UITextFieldDelegate
{
    @IBOutlet weak var themeHeading: UINavigationItem!
    @IBOutlet weak var leaderboardStackView: UIStackView!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var addScoreButton: UIButton!
    @IBOutlet var safeAreaView: UIView!

    public static let lowestScorePosible = Int64(-100)

    var alertController = UIAlertController()

    var gcEnabled = false // Check if the user has Game Center enabled
    var gcDefaultLeaderboardIdentifier = "com.mretondo.EmojiMatch2" // Check the default leaderboardID
    let gcLeaderboardIdentifier = "com.mretondo.EmojiMatch2"

    @IBAction func addTheme(_ sender: UIBarButtonItem) {
        let moc = AppDelegate.shared.coreDataStack.moc

        alertController = UIAlertController(title: "Create your own Theme", message: "Must contain 10 or more Characters", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.delegate = self
            textField.placeholder = "Name"
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: .editingChanged)
        }

//        alertController.addTextField { textField in
//            textField.addConstraint(textField.heightAnchor.constraint(equalToConstant: 2))
//            textField.isEnabled = false
//        }

        alertController.addTextField { textField in
            textField.delegate = self
            textField.placeholder = "Characters"
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: .editingChanged)
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [self] _ in
            guard let nameTextField = alertController.textFields?.first,
                  let charactersTextField = alertController.textFields?.last else { return }

            let newTheme = Theme(context: moc)

            newTheme.name             = nameTextField.text
            newTheme.emojis           = charactersTextField.text
            // use default colors
            newTheme.backgroundColor  = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            newTheme.faceDownColor    = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
            newTheme.faceUpColor      = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)

            AppDelegate.shared.coreDataStack.saveMoc()
        }
        saveAction.isEnabled = false
        alertController.addAction(saveAction)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alertController, animated: true)
//        present(alertController, animated: true, completion: {
//            if let textField = alertController.textFields?[1] {
//                textField.transparentBackground()
//            }
//        })
    }

    @objc func alertTextFieldDidChange(_ textField: UITextField) {
        let saveAction: UIAlertAction = alertController.actions.first!
        saveAction.isEnabled = false

        if let themeName = alertController.textFields?.first?.text, themeName.count > 0 {
            // themes must have 10 characters or more
            if let themeCharacters = alertController.textFields?.last?.text, themeCharacters.count >= 10 {
                saveAction.isEnabled = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Call the GC authentication controller
        authenticateLocalPlayer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        let views = view.subviews

        updateAppHighScoreTextField()

        // give leaderboardStackView a background color as wide as the safeAreaView
        pinBackgroundView(backgroundView,
                          toStackView: leaderboardStackView,
                          leading: safeAreaView.leadingAnchor,
                          trailing: safeAreaView.trailingAnchor,
                          top: leaderboardStackView.topAnchor,
                          bottom: leaderboardStackView.bottomAnchor
        )

//        themeHeading.rightBarButtonItem?.isHidden = !self.gcEnabled
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
                        // If user deleted there local database score this will try to update
                        // it with the score from there Leaderboard score if it exists.
                        if AppDelegate.shared.highScore == nil {
                            Task {
                                await self.updateAppScoreFromLeaderboard()
                            }
                        }
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
        gameCenterViewController.dismiss(animated: true)
    }

    @IBAction func checkGCLeaderboard(_ sender: Any) {
        let gcVC = GKGameCenterViewController(leaderboardID: gcLeaderboardIdentifier, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = self

        present(gcVC, animated: true, completion: nil)
    }

    @IBAction func addScoreAndSubmitToGC(_ sender: Any) {
        if let highestScore = AppDelegate.shared.highScore {
            Task {
                // get score from the leaderboard if one exists
                if let leaderboardHighestScore = try await getHighScoreFromLeadboardForLocalPlayer(), leaderboardHighestScore >= highestScore {
                    self.showOkAlert(title: "Your leaderboard score is already the best.", message: "")
                } else {
                    // Submit best score to GC leaderboard
                    GKLeaderboard.submitScore(Int(highestScore), context: 0, player: GKLocalPlayer.local, leaderboardIDs: [self.gcLeaderboardIdentifier]) { error in
                        if error == nil {
                            self.showOkAlert(title: "Success", message: "Your score was added to the Leaderboard.")
                        } else {
                            self.showOkAlert(title: "The score was unable to be added to the Leaderboard.", message: "error!.localizedDescription")
                        }
                    }
                }
            }
        }
    }

    func getHighScoreFromLeadboardForLocalPlayer() async throws -> Int? {
        var score: Int? = nil

        // Check if the user is authenticated
        if (GKLocalPlayer.local.isAuthenticated) {
            if let leaderboards = await loadLeaderboards() {
                let (localPlayer, _) = try await leaderboards[0].loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime)
                if let localPlayer = localPlayer {
                    score = localPlayer.score
                }
            } else {
                #if DEBUG
                print("getHighScoreFromLeadboardForLocalPlayer() - Can't loadLeaderboards")
                #endif
            }
        } else {
            #if DEBUG
            print("getHighScoreFromLeadboardForLocalPlayer() - Player is not authenticated")
            #endif
        }

        return score
    }

//    func loadEntries(for leaderboard: GKLeaderboard) async -> Int? {
//        // since it's an async function, we are allowed to use await
//        await withCheckedContinuation { continuation in
//            leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime) { player, _, error in
//                var score: Int? = nil
//
//                if let player = player {
//                    score = player.score
//                } else {
//#if DEBUG
//                    print("getHighScoreFromLeadboardForLocalPlayer() - GKLeaderboard.loadEntries() - " + error.debugDescription)
//#endif
//                }
//
//                // resume the awaiting call to withCheckedContinuation
//                continuation.resume(returning: score)
//            }
//        }
//    }

    func loadLeaderboards() async -> [GKLeaderboard]? {
        // since it's an async function, we are allowed to use await
        await withCheckedContinuation { continuation in
            GKLeaderboard.loadLeaderboards(IDs: [gcLeaderboardIdentifier]) { leaderboards, error in
                if error != nil {
                    #if DEBUG
                    print("loadLeaderboards() - GKLeaderboard.loadLeaderboards() - " + error.debugDescription)
                    #endif
                }

                // resume the awaiting call to withCheckedContinuation
                continuation.resume(returning: leaderboards)
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

    // If user deleted there local database score this will try to update
    // it with the score from there Leaderboard score if it exists.
    func updateAppScoreFromLeaderboard() async {
        if let leaderboardHighestScore = try? await getHighScoreFromLeadboardForLocalPlayer() {
            updateAppHighScore(with: Int64(leaderboardHighestScore))

            do {
                // save score to Core Data
                try AppDelegate.shared.coreDataStack.moc.save()

                updateAppHighScoreTextField()

                #if DEBUG
                print("Best score from Game Center: \(leaderboardHighestScore)")
                #endif
            } catch {
                print("updateScoreFromLeaderboard() - Couldn't save viewContext")
            }
        } else {
            print("updateScoreFromLeaderboard() - Couldn't getHighScoreFromLeadboardForLocalPlayer")
        }
    }

    /// set applications high score if none yet exists or update it to a better score
    func updateAppHighScore(with score: Int64) {
        if score >= LeaderboardTableViewController.lowestScorePosible {
            if let highScore = AppDelegate.shared.highScore {
                // compare score to current high score
                if score > highScore {
                    AppDelegate.shared.highScore = score
                }
            } else {
                // no high score recorded yet
                AppDelegate.shared.highScore = score
            }
        }
    }

    /// update the applications high score TextField
    fileprivate func updateAppHighScoreTextField() {
        // update UI on main thread
        return DispatchQueue.main.async { [self] in
            if var prompt = themeHeading.prompt, let appendIndex = prompt.index(after: ": ") {
                prompt = String(prompt.prefix(upTo: appendIndex))

                if let highestScore = AppDelegate.shared.highScore {
                    prompt.append("\(highestScore)")
                }

                themeHeading.prompt = prompt
            }
        }
    }

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


extension UITextField {
    func transparentBackground() {
        superview?.backgroundColor = .clear

        let view = superview?.superview
        view?.subviews.first?.alpha = 0
        view?.backgroundColor = .clear
    }
}
