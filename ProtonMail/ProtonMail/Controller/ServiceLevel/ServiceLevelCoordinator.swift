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
        var child: SomeCoordinator!
        
        switch next {
        case .buyMore:
            child = ServiceLevelCoordinator() as? SomeCoordinator
            let viewModel = BuyMoreViewModel()
            viewModel.setup(with: ServicePlanDataService.currentServicePlan)
            (child.controller as? ServiceLevelViewController)?.viewModel = viewModel
            
        case .details(of: let plan):
            child = ServiceLevelCoordinator() as? SomeCoordinator
            let viewModel = PlanDetailsViewModel()
            viewModel.setup(with: plan)
            (child.controller as? ServiceLevelViewController)?.viewModel = viewModel
        }
        
        return child
    }
    
    weak var controller: UIViewController! = ServiceLevelCoordinator.makeController()
    
    private class func makeController() -> ServiceLevelViewController {
        let controller = UIStoryboard(name: "ServiceLevel", bundle: .main).make(ServiceLevelViewController.self)
        controller.viewModel = PlanAndLinksViewModel()
        controller.viewModel.setup(with: ServicePlanDataService.currentServicePlan)
        return controller
    }
    
    enum Destination {
        case details(of: ServicePlan)
        case buyMore
    }
}
