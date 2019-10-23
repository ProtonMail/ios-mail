//
//  Coordinator.swift
//  ProtonMail - Created on 08/08/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

fileprivate var CoordinatorKey = "CoordinatorKey"

@available(*, deprecated, message: "double check if ok to remove")
protocol Coordinated {
    associatedtype CoordinatorType
}

extension Coordinated where Self: UIViewController {
    var coordinator: CoordinatorType! {
        get {
            return objc_getAssociatedObject(self, &CoordinatorKey) as? CoordinatorType
        }
        set {
            objc_setAssociatedObject(self, &CoordinatorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

@available(*, deprecated, message: "double check if ok to remove")
protocol Coordinator: class {
    associatedtype Destination
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: Destination) -> SomeCoordinator
    func insertIntoHierarchy(_ child: UIViewController)
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
