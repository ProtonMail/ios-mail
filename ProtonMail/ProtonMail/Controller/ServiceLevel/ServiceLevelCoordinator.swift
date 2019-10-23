//
//  ServiceLevelCoordinator.swift
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
