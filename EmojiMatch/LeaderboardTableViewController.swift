//
//  LeaderboardTableViewController.swift
//  Match Emojis
//
//  Created by Mike Retondo on 2/15/20.
//

import Foundation
import UIKit
import MRUtils
@preconcurrency import GameKit

@MainActor
final class LeaderboardTableViewController: UIViewController, UITextFieldDelegate, GKGameCenterControllerDelegate {
    @IBOutlet weak var themeHeading: UINavigationItem!
    @IBOutlet weak var leaderboardStackView: UIStackView!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var addScoreButton: UIButton!
    @IBOutlet var safeAreaView: UIView!

    static let lowestScorePossible = Int64(-100)

    private var alertController = UIAlertController()

    private let gcLeaderboardIdentifier = "com.mretondo.EmojiMatch26"

    @IBAction private func addTheme(_ sender: UIBarButtonItem) {
        alertController = UIAlertController(
            title: "Create your own Theme",
            message: "Must contain 10 or more Characters",
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.delegate = self
            textField.placeholder = "Name"
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: .editingChanged)
        }

        alertController.addTextField { textField in
            textField.delegate = self
            textField.placeholder = "Characters"
            textField.addTarget(self, action: #selector(self.alertTextFieldDidChange(_:)), for: .editingChanged)
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { [self] _ in
            guard let nameTextField = alertController.textFields?.first,
                  let charactersTextField = alertController.textFields?.last else { return }

            let coreDataStack = AppEnvironment.shared.coreDataStack

            let themeItem = ThemeItem(name: nameTextField.text!,
                                      emojis: charactersTextField.text!,
                                      backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
                                      faceDownColor: #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1),
                                      faceUpColor: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))

            coreDataStack.insertTheme(from: themeItem)
        }

        saveAction.isEnabled = false
        alertController.addAction(saveAction)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alertController, animated: true)
    }

    @objc private func alertTextFieldDidChange(_ textField: UITextField) {
        guard let saveAction = alertController.actions.first else { return }

        saveAction.isEnabled = false

        if let themeName = alertController.textFields?.first?.text, !themeName.isEmpty,
           let themeCharacters = alertController.textFields?.last?.text, themeCharacters.count >= 10 {
            saveAction.isEnabled = true
        }
    }

    // Note: this function gets called with only a single char most of the time but can contain more if text is pasted
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // only check the second field in the dialog which is meant to contain the characters for the Cards
        if textField == alertController.textFields?.last {
            // Get the current text, or an empty string if it's nil
            let currentText = textField.text ?? ""

            // Attempt to create a Swift Range from the NSRange
            guard Range(range, in: currentText) != nil else {
                return false // If range is invalid, prevent change
            }

            // If user deleted text, the string will be empty
            if string.isEmpty {
                return true
            }

            // Smart Punctuation on iOS can add a space to the front and back of
            // the pasted string so I only allow 1 character.
            if string.count > 1 {
                return false
            }

            // Check if string contains any whitespace
            if string.rangeOfCharacter(from: .whitespaces) != nil {
                // the string contains at least one character from the whitespaces set
                return false
            }

            // prevent duplicate characters
            if let text = textField.text, text.contains(string) {
                return false
            }
        }

        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        if previouslyLaunched {
            AppEnvironment.shared.easyScoringMode = UserDefaults.standard.bool(forKey: "easyScoringMode")
        }

        configureEasyScoringSwitchBarItem()

        // Call the GC authentication controller
        authenticateLocalPlayer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateAppHighScoreTextField()

        // give leaderboardStackView a background color as wide as the safeAreaView
        pinBackgroundView(
            backgroundView,
            toStackView: leaderboardStackView,
            leading: safeAreaView.leadingAnchor,
            trailing: safeAreaView.trailingAnchor,
            top: leaderboardStackView.topAnchor,
            bottom: leaderboardStackView.bottomAnchor
        )
    }

    private func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }

            if let viewController {
                // Show login if player is not logged in
                self.present(viewController, animated: true)
            } else if localPlayer.isAuthenticated {
                // Player is already authenticated & logged in

                // Get the default leaderboard ID
                Task {
                    do {
                        _ = try await localPlayer.loadDefaultLeaderboardIdentifier()

                        // If user deleted their local database score, update it from the leaderboard
                        if AppDelegate.shared.highScore == nil {
                            await self.updateAppScoreFromLeaderboard()
                        }
                    } catch {
                        #if DEBUG
                        print("authenticateLocalPlayer() error: \(error)")
                        #endif
                    }
                }

                self.leaderboardButton.isEnabled = true
                self.addScoreButton.isEnabled = true
            } else {
                // Game center is not enabled on the user's device
                self.leaderboardButton.isEnabled = false
                self.addScoreButton.isEnabled = false

                #if DEBUG
                print("Local player could not be authenticated!")
                if let error {
                    print(error.localizedDescription)
                }
                #endif
            }
        }
    }

    @IBAction private func checkGCLeaderboard(_ sender: Any) {
        let gcViewController = GKGameCenterViewController(leaderboardID: gcLeaderboardIdentifier, playerScope: .global, timeScope: .allTime)
        gcViewController.gameCenterDelegate = self
        present(gcViewController, animated: true)
    }

    // MARK: - GKGameCenterControllerDelegate

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }


    @IBAction private func addScoreAndSubmitToGC(_ sender: Any) {
        guard let highestScore = AppDelegate.shared.highScore else { return }

        Task {
            do {
                // Get score from the leaderboard if one exists
                if let leaderboardHighestScore = try await getHighScoreFromLeaderboardForLocalPlayer(),
                   leaderboardHighestScore >= highestScore {
                    showOkAlert(title: "Your leaderboard score is already the best.", message: "")
                } else {
                    // Submit best score to GC leaderboard
                    try await GKLeaderboard.submitScore(
                        Int(highestScore),
                        context: 0,
                        player: GKLocalPlayer.local,
                        leaderboardIDs: [gcLeaderboardIdentifier]
                    )

                    showOkAlert(title: "Success", message: "Your score was added to the Leaderboard.")
                }
            } catch {
                showOkAlert(
                    title: "The score was unable to be added to the Leaderboard.",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func getHighScoreFromLeaderboardForLocalPlayer() async throws -> Int? {
        guard GKLocalPlayer.local.isAuthenticated else {
            #if DEBUG
            print("getHighScoreFromLeaderboardForLocalPlayer() - Player is not authenticated")
            #endif
            return nil
        }

        guard let leaderboards = await loadLeaderboards() else {
            #if DEBUG
            print("getHighScoreFromLeaderboardForLocalPlayer() - Can't loadLeaderboards")
            #endif
            return nil
        }

        let (localPlayer, _) = try await leaderboards[0].loadEntries(
            for: [GKLocalPlayer.local],
            timeScope: .allTime
        )

        return localPlayer?.score
    }

    private func loadLeaderboards() async -> [GKLeaderboard]? {
        do {
            return try await GKLeaderboard.loadLeaderboards(IDs: [gcLeaderboardIdentifier])
        } catch {
            #if DEBUG
            print("loadLeaderboards() - GKLeaderboard.loadLeaderboards() - " + String(describing: error))
            #endif
            return nil
        }
    }

    /// shows Alert with OK button
    private func showOkAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }

    // If user deleted their local database score, this will try to update
    // it with the score from their Leaderboard score if it exists.
    private func updateAppScoreFromLeaderboard() async {
        if let leaderboardHighestScore = try? await getHighScoreFromLeaderboardForLocalPlayer() {
            updateAppHighScore(with: Int64(leaderboardHighestScore))

            // Note: Score.highScore setter automatically saves to Core Data
            updateAppHighScoreTextField()

            #if DEBUG
            print("Best score from Game Center: \(leaderboardHighestScore)")
            #endif
        } else {
            #if DEBUG
            print("updateScoreFromLeaderboard() - Couldn't getHighScoreFromLeaderboardForLocalPlayer")
            #endif
        }
    }

    /// set applications high score if none yet exists or update it to a better score
    private func updateAppHighScore(with score: Int64) {
        if score >= LeaderboardTableViewController.lowestScorePossible {
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
        // Already on main actor due to @MainActor on the class
        if var prompt = themeHeading.prompt, let appendIndex = prompt.firstIndex(where: { $0 == ":" }) {
            let colonIndex = prompt.index(after: appendIndex)
            prompt = String(prompt.prefix(upTo: colonIndex))
            prompt.append(" ")

            if let highestScore = AppDelegate.shared.highScore {
                prompt.append("\(highestScore)")
            }

            themeHeading.prompt = prompt
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

    private func configureEasyScoringSwitchBarItem() {
        let switchView = LabeledSwitchView(labelText: "Easy Scoring", isOn: AppEnvironment.shared.easyScoringMode) { isOn in
            AppEnvironment.shared.easyScoringMode = isOn
        }

        // Add to navigation item
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: switchView)
    }
}

// MARK: - LabeledSwitchView

/// A reusable view that contains a label and switch in a horizontal stack
final class LabeledSwitchView: UIStackView {
    private let label = UILabel()
    private let toggleSwitch = UISwitch()
    private var onValueChanged: ((Bool) -> Void)?

    /// Creates a labeled switch view with a closure-based action handler
    /// - Parameters:
    ///   - labelText: The text to display in the label
    ///   - isOn: The initial state of the switch
    ///   - spacing: The spacing between the label and switch (default: 8)
    ///   - onValueChanged: Closure called when the switch value changes
    init(labelText: String, isOn: Bool, spacing: CGFloat = 8, onValueChanged: @escaping (Bool) -> Void) {
        self.onValueChanged = onValueChanged
        super.init(frame: .zero)

        setupView(labelText: labelText, isOn: isOn, spacing: spacing)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView(labelText: "", isOn: false, spacing: 8)
    }

    private func setupView(labelText: String, isOn: Bool, spacing: CGFloat) {
        // Configure label
        label.text = labelText
        label.textColor = .label // works with light/dark modes

        // Configure switch
        toggleSwitch.isOn = isOn
        toggleSwitch.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                self.onValueChanged?(self.toggleSwitch.isOn)
            },
            for: .valueChanged
        )

        // Configure stack view
        axis = .horizontal
        self.spacing = spacing
        addArrangedSubview(label)
        addArrangedSubview(toggleSwitch)

        // Fix to prevent right edge of the switch from getting truncated which removes rounded look
        isLayoutMarginsRelativeArrangement = true
    }

    /// Updates the switch state programmatically
    func setOn(_ isOn: Bool, animated: Bool = false) {
        toggleSwitch.setOn(isOn, animated: animated)
    }

    /// The current state of the switch
    var isOn: Bool {
        toggleSwitch.isOn
    }
}
