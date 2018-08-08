//
//  ServiceLevelCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class SettingsCoordinator: Coordinator {
    @discardableResult func go<SomeCoordinator: Coordinator>(to next: SettingsCoordinator.Destination) -> SomeCoordinator {
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
    func go<SomeCoordinator: Coordinator>(to next: ServiceLevelCoordinator.Destination) -> SomeCoordinator {
        var child: SomeCoordinator!
        
        switch next {
        case .buyMore:
            child = BuyMoreCoordinator() as? SomeCoordinator
        default: fatalError()
        }
        
        return child
    }
    
    lazy var controller: UIViewController! = {
        var controller = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewController.self)
        controller.coordinator = self
        return controller
    }()
    
    enum Destination {
        case changePayedPlan(to: ServicePlan)
        case chooseFirstPayedPlan(ServicePlan)
        case currentPlan
        case buyMore
    }
}

class BuyMoreCoordinator: Coordinator {
    func go<SomeCoordinator: Coordinator>(to next: Never) -> SomeCoordinator {
        fatalError()
    }
    
    lazy var controller: UIViewController! = {
        let controller = UIStoryboard(name: "ServiceLevel", bundle: .main).make(BuyMoreViewController.self)
        return controller
    }()
    
    typealias Destination = Never
}
class BuyMoreViewController: UIViewController {
    
}
