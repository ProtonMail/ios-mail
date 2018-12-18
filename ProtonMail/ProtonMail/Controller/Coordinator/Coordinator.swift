//
//  Coordinator.swift
//  ProtonMail - Created on 08/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
