//
//  FirstResponder.swift
//  Match Emojis
//
//  Created by Mike Retondo on 2/6/26.
//

import UIKit

extension UIResponder {
    private weak static var _currentFirstResponder: UIResponder? = nil

    //
    // retrive the applications firstResponder
    //
    public static var currentFirstResponder: UIResponder? {
        UIResponder._currentFirstResponder = nil

        //
        // The trick here is that iOS documentation for sendAction(_:to:from:for:) states the following:
        // If target is nil, the app sends the message to the first responder,
        // from whence it progresses up the responder chain until it is handled.
        //
        // So when you want to retrieve the first responder, you can call:
        // let currentFirstResponder = UIResponder.currentFirstResponder
        //
        // NOTE: Subclasses may override this method to perform special dispatching of action messages.
        //
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)

        return UIResponder._currentFirstResponder
    }

    @objc internal func findFirstResponder(sender: AnyObject) {
        UIResponder._currentFirstResponder = self
    }
}


// You can't really find the current first responder if it is not in the view hierarchy.
// For example, AppDelegate or UIViewController subclasses.

// There is a way to guarantee you to find it even if the first responder object is not a UIView.

// First lets implement a reversed version of it, using the next property of UIResponder:
extension UIResponder {
    var nextFirstResponder: UIResponder? {
        return isFirstResponder ? self : next?.nextFirstResponder
    }
}

// With this computed property, we can find the current first responder from bottom to top even if it's not UIView.
// For example, from a view to the UIViewController who's managing it, if the view controller is the first responder.
//
// However, we still need a top-down resolution, a single var to get the current first responder.
//
// First with the view hierarchy:
extension UIView {
    var previousFirstResponder: UIResponder? {
        return nextFirstResponder ?? subviews.compactMap { $0.previousFirstResponder }.first
    }
}

// This will search for the first responder backwards, and if it couldn't find it, it would tell its subviews to do the same
// thing (because its subview's next is not necessarily itself). With this we can find it from any view, including UIWindow.
//
// And finally, we can build this:
extension UIResponder {
    static var first: UIResponder? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.compactMap { $0.previousFirstResponder }.first
    }
}

// So when you want to retrieve the first responder, you can call:
// let firstResponder = UIResponder.first
