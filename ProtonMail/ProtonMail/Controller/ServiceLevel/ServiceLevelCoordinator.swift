//
//  ServiceLevelCoordinator.swift
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

class BuyMoreCoordinator: Coordinator {
    func make<SomeCoordinator>(coordinatorFor next: Never) -> SomeCoordinator where SomeCoordinator : Coordinator {
        fatalError()
    }
    
    init() {
        let superController = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewControllerBase.self)
        object_setClass(superController, BuyMoreViewController.self)
        if let subscription = ServicePlanDataService.shared.currentSubscription {
            (superController as! BuyMoreViewController).setup(with: subscription)
        }
        self.controller = superController
    }
    
    weak var controller: UIViewController!
    
    typealias Destination = Never
}


class PlanDetailsCoordinator: Coordinator {
    weak var controller: UIViewController!
    
    typealias Destination = Never
    
    func make<SomeCoordinator>(coordinatorFor next: PlanDetailsCoordinator.Destination) -> SomeCoordinator {
        fatalError()
    }
    
    init(forPlan plan: ServicePlan) {
        let superController = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewControllerBase.self)
        object_setClass(superController, PlanDetailsViewController.self)
        (superController as! PlanDetailsViewController).setup(with: plan)
        self.controller = superController
    }
}

class ServiceLevelCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: ServiceLevelCoordinator.Destination) -> SomeCoordinator {
        switch next {
        case .buyMore:
            return BuyMoreCoordinator() as! SomeCoordinator
        case .details(of: let plan):
            return PlanDetailsCoordinator(forPlan: plan) as! SomeCoordinator
        }
    }
    
    weak var controller: UIViewController!
    
    init() {
        let superController = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewControllerBase.self)
        object_setClass(superController, ServiceLevelViewController.self)
//        if let subscription = ServicePlanDataService.shared.currentSubscription {
//            (superController as! ServiceLevelViewController).setup(with: subscription)
//        }
        (superController as! ServiceLevelViewController).setup(with: nil)
        self.controller = superController
    }
    
    enum Destination {
        case details(of: ServicePlan)
        case buyMore
    }
}
