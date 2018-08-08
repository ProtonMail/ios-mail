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
extension Coordinated where Self: UIViewController {
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
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: Destination) -> SomeCoordinator
    var controller: UIViewController! { get set }
}
extension Coordinator {
    func insertIntoHierarchy(_ child: UIViewController) {
        guard let navigationController = self.controller?.navigationController else {
            self.controller.present(child, animated: true, completion: nil)
            return
        }
        navigationController.pushViewController(child, animated: true)
    }
    
    @discardableResult
    func go<VC: UIViewController&Coordinated>(to destination: Destination,
                                                 creating someType: VC.Type) -> VC.CoordinatorType where VC.CoordinatorType: Coordinator
    {
        let nextCoordinator: VC.CoordinatorType = self.make(coordinatorFor: destination)
        if var nextController = nextCoordinator.controller as? VC {
            nextController.coordinator = nextCoordinator
        }
        self.insertIntoHierarchy(nextCoordinator.controller)
        return nextCoordinator
    }
}
