//
//  TargetAction.swift
//
//  Created by Mike Retondo on 5/29/21.
//

import UIKit

protocol TargetAction {
    func performAction()
}

struct TargetActionWrapper<T: AnyObject> : TargetAction {
    weak var target: T?
    let action: (T) -> () -> ()

    func performAction() -> () {
        if let t = target {
            action(t)()
        }
    }
}

enum ControlEvent {
    case touchUpInside
    case valueChanged
    // ...
}

@available(iOS 14.0, *)
class Control {
    var actions = [ControlEvent: TargetAction]()

    func setTarget<T: AnyObject>(_ target: T, action: @escaping (T) -> () -> (), controlEvent: ControlEvent) {
        actions[controlEvent] = TargetActionWrapper(target: target, action: action)
    }

    func removeTarget(for controlEvent: ControlEvent) {
        actions[controlEvent] = nil
    }

    func performAction(for controlEvent: ControlEvent) {
        actions[controlEvent]?.performAction()
    }
}

/* Usage:
class MyViewController {
    let button = Control()

    func viewDidLoad() {
        button.setTarget(self, action: MyViewController.buttonTap, controlEvent: .touchUpInside)
    }

    func buttonTap() {
        print("Button was tapped")
    }
}
*/
