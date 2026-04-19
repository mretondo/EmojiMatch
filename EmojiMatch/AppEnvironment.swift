//
//  AppEnvironment.swift
//  Match Emojis
//
//  Created by Mike Retondo on 1/3/26.
//


@MainActor
class AppEnvironment {
    private init() {} // Prevents others from creating an instance

    static let shared = AppEnvironment() // Singleton instance

    var easyScoringMode = false

    lazy var coreDataStack: CoreDataStack = CoreDataStack(name: "Model")

    weak var themeChooserTableViewController: ThemeChooserTableViewController?
}
