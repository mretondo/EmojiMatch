//
//  AppEnvironment.swift
//  Match Emojis
//
//  Created by Mike Retondo on 1/3/26.
//


class AppEnvironment {
    static let shared = AppEnvironment() // Singleton instance
    var sharedDataValue: String?
    private init() {} // Prevents others from creating an instance
}
