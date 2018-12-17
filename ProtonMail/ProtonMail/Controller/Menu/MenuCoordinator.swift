//
//  SettingsCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 09/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import SWRevealViewController

class MenuCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: MenuCoordinator.Destination) -> SomeCoordinator {
        guard next == .serviceLevel else {
            fatalError()
        }
        let nextCoordinator = ServiceLevelCoordinator(navigationController: self.navigationController)
        return nextCoordinator as! SomeCoordinator
    }
    
    weak var controller: UIViewController!
    private let navigationController = UINavigationController()
    
    enum Destination {
        case serviceLevel
    }
    
    private var observation: NSKeyValueObservation!
    func insertIntoHierarchy(_ child: UIViewController) {
        let menuButton = UIBarButtonItem(image: UIImage(named: "hamburger")!, style: .plain, target: nil, action: nil)
        self.navigationController.viewControllers = [child]
        let segue = SWRevealViewControllerSeguePushController(identifier: String(describing: type(of:child)),
                                                              source: self.controller,
                                                              destination: navigationController)
        
        observation = navigationController.observe(\UINavigationController.parent) { (controller, change) in
            ProtonMailViewController.setup(child, menuButton, true)
            self.observation = nil
        }
        
        self.controller.prepare(for: segue, sender: self)
        segue.perform()
    }
}

