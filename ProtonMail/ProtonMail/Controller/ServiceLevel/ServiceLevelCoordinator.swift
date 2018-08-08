//
//  ServiceLevelCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class SettingsCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: SettingsCoordinator.Destination) -> SomeCoordinator {
        guard next == .serviceLevel else {
            fatalError()
        }
        let nextCoordinator = ServiceLevelCoordinator()
        return nextCoordinator as! SomeCoordinator
    }
    
    var controller: UIViewController!
    
    enum Destination {
        case serviceLevel
    }
}

class ServiceLevelCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: ServiceLevelCoordinator.Destination) -> SomeCoordinator {
        var child: SomeCoordinator!
        
        switch next {
        case .buyMore:
            child = BuyMoreCoordinator() as? SomeCoordinator
        default: fatalError()
        }
        
        return child
    }
    
    lazy var controller: UIViewController! = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewController.self)
    
    enum Destination {
        case changePayedPlan(to: ServicePlan)
        case chooseFirstPayedPlan(ServicePlan)
        case currentPlan
        case buyMore
    }
}

class BuyMoreCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: Never) -> SomeCoordinator {
        fatalError()
    }
    
    lazy var controller: UIViewController! = UIStoryboard(name: "ServiceLevel", bundle: .main).make(BuyMoreViewController.self)
    
    typealias Destination = Never
}
class BuyMoreViewController: UIViewController, Coordinated {
    typealias CoordinatorType = BuyMoreCoordinator
    
    
}
