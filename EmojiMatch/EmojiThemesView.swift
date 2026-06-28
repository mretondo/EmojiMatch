//
//  EmojiThemesView.swift
//

import SwiftUI
import UIKit
import CoreData
import GameKit

struct EmojiThemesView: View {
    @Environment(\.managedObjectContext) private var moc
    @Environment(AppEnvironment.self) private var appEnvironment
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @FetchRequest(sortDescriptors: [SortDescriptor(\Theme.name, comparator: .localizedStandard)])
    private var themes: FetchedResults<Theme>

    @FetchRequest(sortDescriptors: [])
    private var scores: FetchedResults<Score>

    @State private var showAddTheme = false
    @State private var isGCAuthenticated = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var emojiCache: [String: String] = [:]

    private var highScore: Int64? { scores.first?.highScore }

    var body: some View {
        @Bindable var appEnvironment = appEnvironment
        NavigationStack {
            List {
                ForEach(themes) { theme in
                    if let item = ThemeItem(from: theme) {
                        NavigationLink(value: item) {
                            ThemeRow(theme: theme, emojiCache: $emojiCache)
                        }
                    }
                }
                .onDelete(perform: deleteThemes)
            }
            .listStyle(.plain)
            .navigationTitle("Emoji Themes")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ThemeItem.self) { item in
                CardGameView(theme: item)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle(isOn: $appEnvironment.easyScoringMode) {
                        Text("Easy Scoring").font(.footnote)
                    }
                    .toggleStyle(.switch)
                    .fixedSize()
                    .padding(.trailing, 3)
                }
                ToolbarItem(placement: .principal) {
                    let scoreText = highScore.map { "High Score: \($0)" } ?? "High Score: --"
                    if verticalSizeClass == .compact {
                        HStack {
                            Text("Emoji Themes")
                                .font(.headline)
                                .padding(.horizontal, 40)
                            Text(scoreText)
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    } else {
                        Text(scoreText)
                            .font(.caption)
                            .foregroundStyle(.tint)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddTheme = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // needed to stop runtime error message: Adding 'UIKitToolbar' as a subview of UIHostingController.view is not supported...
            .safeAreaInset(edge: .bottom) {
                GlassEffectContainer {
                    HStack(spacing: 0) {
                        Button {
                            GKAccessPoint.shared.trigger(leaderboardID: "com.mretondo.EmojiMatch26",
                                                         playerScope: .global,
                                                         timeScope: .allTime) {}
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "list.number")
                                Text("Leaderboard")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                        }
                        .disabled(!isGCAuthenticated)

                        Divider()
                            .frame(height: 30)

                        Button { submitScore() } label: {
                            VStack(spacing: 2) {
                                Image("trophy.badge.arrow.up")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                Text("Score")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                        }
                        .disabled(!isGCAuthenticated)
                    }
                    .glassEffect(in: .capsule)
                    .tint(.primary)
                }
            }

            .sheet(isPresented: $showAddTheme) {
                AddThemeSheet()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear { authenticateGameCenter() }
    }

    // MARK: - Private

    private func deleteThemes(at offsets: IndexSet) {
        for index in offsets {
            moc.delete(themes[index])
        }
        try? moc.save()
    }

    private func authenticateGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { _, _ in
            Task { @MainActor in
                self.isGCAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self.isGCAuthenticated && self.highScore == nil {
                    await self.updateScoreFromLeaderboard()
                }
            }
        }
    }

    private func submitScore() {
        guard let highestScore = highScore else { return }
        Task { @MainActor in
            do {
                let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: ["com.mretondo.EmojiMatch26"])
                if let leaderboard = leaderboards.first {
                    let (entry, _) = try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime)
                    if let existing = entry?.score, existing >= Int(highestScore) {
                        show(title: "Your leaderboard score is already the best.", message: "")
                        return
                    }
                }
                try await GKLeaderboard.submitScore(
                    Int(highestScore), context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: ["com.mretondo.EmojiMatch26"]
                )
                show(title: "Success", message: "Your score was added to the Leaderboard.")
            } catch {
                show(title: "Score could not be submitted.", message: error.localizedDescription)
            }
        }
    }

    @MainActor
    private func updateScoreFromLeaderboard() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: ["com.mretondo.EmojiMatch26"])
            if let leaderboard = leaderboards.first {
                let (entry, _) = try await leaderboard.loadEntries(for: [GKLocalPlayer.local], timeScope: .allTime)
                if let gcScore = entry?.score {
                    Score.highScore = Int64(gcScore)
                }
            }
        } catch {}
    }

    private func show(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Theme row

private struct ThemeRow: View {
    let theme: Theme
    @Binding var emojiCache: [String: String]

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 40))
            Text(theme.name ?? "")
                .font(.system(size: 40))
        }
    }

    private var emoji: String {
        guard let name = theme.name, let emojis = theme.emojis else { return "?" }
        if let cached = emojiCache[name] { return cached }
        let picked = pickRandom(from: emojis)
        emojiCache[name] = picked
        return picked
    }

    private func pickRandom(from emojis: String) -> String {
        guard !emojis.isEmpty else { return "?" }
        let offset = emojis.count.random
        let index = emojis.index(emojis.startIndex, offsetBy: offset)
        return String(emojis[index])
    }
}

// MARK: - Add Theme sheet

private struct AddThemeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var moc

    @State private var name = ""
    @State private var characters = ""

    private var isValid: Bool { !name.isEmpty && characters.count >= 10 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Characters", text: $characters)
                        .onChange(of: characters) { _, newValue in
                            // Strip whitespace and duplicates, enforce single-char input
                            let filtered = newValue
                                .filter { !$0.isWhitespace }
                                .reduce(into: "") { result, ch in
                                    if !result.contains(ch) { result.append(ch) }
                                }
                            if filtered != newValue { characters = filtered }
                        }
                } header: {
                    Text("Must contain 10 or more characters")
                }
            }
            .navigationTitle("Create your own Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let item = ThemeItem(
            name: name,
            emojis: characters,
            backgroundColor: .white,
            faceDownColor: UIColor(red: 0.017, green: 0.198, blue: 1, alpha: 1),
            faceUpColor: UIColor(red: 0.804, green: 0.804, blue: 0.804, alpha: 1)
        )
        AppEnvironment.shared.coreDataStack.insertTheme(from: item)
        dismiss()
    }
}

