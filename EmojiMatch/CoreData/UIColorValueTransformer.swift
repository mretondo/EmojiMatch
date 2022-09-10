//
//  UIColorValueTransformer.swift
//  Match Emojis
//
//  Created by Mike Retondo on 1/26/21.
//

import Foundation
import SwiftUI

// Subclass from `NSSecureUnarchiveFromDataTransformer`
@objc(UIColorValueTransformer)
final class UIColorValueTransformer: NSSecureUnarchiveFromDataTransformer {

    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTransformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: UIColorValueTransformer.self))

    // Make sure `UIColor` is in the allowed class list.
    override static var allowedTopLevelClasses: [AnyClass] {
        return [UIColor.self]
    }

    /// Registers the transformer.
    /// A good time to do this is right before setting up the persistent container.
    public static func register() {
        let transformer = UIColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
