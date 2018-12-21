//
//  ServiceLevelCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ServiceLevelCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: ServiceLevelCoordinator.Destination) -> SomeCoordinator {
        fatalError("Drilldown should be performed by CoordinatorNew conformant: StorefrontCoordinator")
    }
    
    weak var controller: UIViewController!
    
    init(navigationController: UINavigationController) {
        let controller = UIStoryboard(name: "ServiceLevel", bundle: .main).make(StorefrontCollectionViewController.self)
        if let currentSubscription = ServicePlanDataService.shared.currentSubscription {
            controller.viewModel = StorefrontViewModel(storefront: Storefront(subscription: currentSubscription))
        } else {
            controller.viewModel = StorefrontViewModel(storefront: Storefront(plan: .free))
        }
        self.controller = controller
        
        defer {
            if let controller = self.controller as? StorefrontCollectionViewController {
                let coordinatorNew = StorefrontCoordinator(navigation: navigationController, config: { _ in })
                controller.set(coordinator: coordinatorNew)
            }
        }
    }
    
    enum Destination { }
}
