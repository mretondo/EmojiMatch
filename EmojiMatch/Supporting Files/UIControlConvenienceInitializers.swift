//
//  UIControlConvenienceInitializers.swift
//  Match Emojis
//
//  Created by Mike Retondo on 5/30/21.
//

import UIKit

@available(iOS 14.0, *)
public typealias Sender = Any

//    generic handler for any UIControl
//    let textField = UITextField { sender in
//        let textField = sender as! UITextField
//        // handle here
//    }
@available(iOS 14.0, *)
public extension UIControl {
    convenience init(handler: @escaping (Sender) -> Void) {
        self.init(
            frame: .zero,
            primaryAction: UIAction { action in
                handler(action.sender!)
            }
        )
    }
}

//    generic handler for any UIControl
//    let textField = UITextField(frame: CGRect(x: 20, y: 100, width: 300, height: 40)) { sender in
//        let textField = sender as! UITextField
//        // handle here
//    }
@available(iOS 14.0, *)
public extension UIControl {
    convenience init(frame: CGRect, handler: @escaping (Sender) -> Void) {
        self.init(
            frame: frame,
            primaryAction: UIAction { action in
                handler(action.sender!)
            }
        )
    }
}

//    let startButton = UIButton(
//        title: "Start",
//        image: UIImage(systemName: "play.circle.fill"),
//        handler: {
//            // handle .touchUpInside
//        }
//    )
@available(iOS 14.0, *)
public extension UIButton {
    convenience init(title: String = "",
                     image: UIImage? = nil,
                     handler: @escaping () -> Void) {
        self.init(primaryAction: UIAction(
            title: title,
            image: image,
            handler: { _ in
                handler()
            }
        ))
    }
}

//    let slider = UISlider { value in
//        // Handle value here
//    }
@available(iOS 14.0, *)
public extension UISlider {
    typealias Value = Float

    convenience init(handler: @escaping (Value) -> Void) {
        self.init(
            frame: .zero,
            primaryAction: UIAction { action in
                let slider = action.sender as! Self
                handler(slider.value)
            }
        )
    }
}

