/**
 *  Animate
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import UIKit

// MARK: - Public

public struct Animation {
    public let duration: TimeInterval
    public let delay: TimeInterval
    public let options: UIView.AnimationOptions
    public let closure: (UIView) -> Void

    public init(duration: TimeInterval = 0.0,
                delay: TimeInterval = 0.0,
                options: UIView.AnimationOptions = [],
                closure: @escaping (UIView) -> Void) {
        self.duration = duration
        self.delay = delay
        self.options = options
        self.closure = closure
    }
}

public extension Animation {
    static func scale(byX x: CGFloat, y: CGFloat, duration: TimeInterval = 0.0, delay: TimeInterval = 0.0, options: UIView.AnimationOptions = []) -> Animation {
        return Animation(duration: duration, delay: delay, options: options) {
            $0.transform = CGAffineTransform(scaleX: x, y: y)
        }
    }

    static func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0) -> Animation {
        return Animation(duration: duration, delay: delay) {
            $0.alpha = 1
        }
    }

    static func fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0.0) -> Animation {
        return Animation(duration: duration, delay: delay) {
            $0.alpha = 0
        }
    }

    static func resize(to size: CGSize, duration: TimeInterval = 0.3, delay: TimeInterval = 0.0) -> Animation {
        return Animation(duration: duration, delay: delay) {
            $0.bounds.size = size
        }
    }

    static func move(byX x: CGFloat, y: CGFloat, duration: TimeInterval = 0.3, delay: TimeInterval = 0.0) -> Animation {
        return Animation(duration: duration, delay: delay) {
            $0.center.x += x
            $0.center.y += y
        }
    }
}

public final class AnimationToken {
    private let view: UIView
    private let animations: [Animation]
    private let mode: AnimationMode
    private var isValid = true

    internal init(view: UIView, animations: [Animation], mode: AnimationMode) {
        self.view = view
        self.animations = animations
        self.mode = mode
    }

    deinit {
        perform {}
    }

    internal func perform(completionHandler: @escaping () -> Void) {
        guard isValid else {
            return
        }

        isValid = false

        switch mode {
        case .inSequence:
            view.performAnimations(animations, completionHandler: completionHandler)
        case .inParallel:
            view.performAnimationsInParallel(animations, completionHandler: completionHandler)
        }
    }
}

public func animate(_ tokens: [AnimationToken]) {
    guard !tokens.isEmpty else {
        return
    }

    var tokens = tokens
    let token = tokens.removeFirst()

    token.perform {
        animate(tokens)
    }
}

public func animate(_ tokens: AnimationToken...) {
    animate(tokens)
}

public extension UIView {
    @discardableResult func animate(_ animations: [Animation]) -> AnimationToken {
        return AnimationToken(
            view: self,
            animations: animations,
            mode: .inSequence
        )
    }

    @discardableResult func animate(_ animations: Animation...) -> AnimationToken {
        return animate(animations)
    }

    @discardableResult func animate(inParallel animations: [Animation]) -> AnimationToken {
        return AnimationToken(
            view: self,
            animations: animations,
            mode: .inParallel
        )
    }

    @discardableResult func animate(inParallel animations: Animation...) -> AnimationToken {
        return animate(inParallel: animations)
    }
}

// MARK: - Internal

internal enum AnimationMode {
    case inSequence
    case inParallel
}

internal extension UIView {
    func performAnimations(_ animations: [Animation], completionHandler: @escaping () -> Void) {
        guard !animations.isEmpty else {
            return completionHandler()
        }

        var animations = animations
        let animation = animations.removeFirst()

        UIView.animate(withDuration: animation.duration, animations: {
            animation.closure(self)
        }, completion: { _ in
            self.performAnimations(animations, completionHandler: completionHandler)
        })
    }

    func performAnimationsInParallel(_ animations: [Animation], completionHandler: @escaping () -> Void) {
        guard !animations.isEmpty else {
            return completionHandler()
        }

        let animationCount = animations.count
        var completionCount = 0

        let animationCompletionHandler = {
            completionCount += 1

            if completionCount == animationCount {
                completionHandler()
            }
        }

        for animation in animations {
            UIView.animate(withDuration: animation.duration, animations: {
                animation.closure(self)
            }, completion: { _ in
                animationCompletionHandler()
            })
        }
    }
}
