//
//  SettingsCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 09/08/2018.
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
