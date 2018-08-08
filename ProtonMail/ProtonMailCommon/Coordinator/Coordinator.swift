//
//  Coordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

fileprivate var CoordinatorKey = "CoordinatorKey"

protocol Coordinated {
    associatedtype CoordinatorType
}
extension Coordinated where Self: NSObject {
    var coordinator: CoordinatorType! {
        get {
            return objc_getAssociatedObject(self, &CoordinatorKey) as? CoordinatorType
        }
        set {
            objc_setAssociatedObject(self, &CoordinatorKey, newValue, .OBJC_ASSOCIATION_RETAIN) // FIXME: need weak ref here?
        }
    }
}

protocol Coordinator: class {
    associatedtype Destination
    // parent AnyCoordinator via type erasure?
    func go<SomeCoordinator: Coordinator>(to next: Destination) -> SomeCoordinator
    var controller: UIViewController! { get set }
}
extension Coordinator {
    func `as`<T>(_ finalType: T.Type) -> T {
        return self as! T
    }
    func show(child: UIViewController) {
        guard let navigationController = self.controller?.navigationController else {
            self.controller.present(child, animated: true, completion: nil)
            return
        }
        navigationController.pushViewController(child, animated: true)
    }
}
