//
//  AppEnvironment.swift
//

import Foundation
import Observation

@Observable
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    var easyScoringMode: Bool {
        didSet { UserDefaults.standard.set(easyScoringMode, forKey: "easyScoringMode") }
    }

    @ObservationIgnored lazy var coreDataStack = CoreDataStack(name: "Model")

    private init() {
        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        easyScoringMode = previouslyLaunched
            ? UserDefaults.standard.bool(forKey: "easyScoringMode")
            : false
    }
}
