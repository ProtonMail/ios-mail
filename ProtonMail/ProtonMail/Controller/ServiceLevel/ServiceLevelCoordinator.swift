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
        
        // FIXME: this is not very correct usage of Coordinator since we will not be able to go to other plan details from the child; child should have coordinator of separate type
        switch next {
        case .buyMore:
            child = ServiceLevelCoordinator() as? SomeCoordinator
            let viewModel = BuyMoreViewModel()
            viewModel.setup(with: ServicePlanDataService.currentSubscription)
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
        let viewModel = PlanAndLinksViewModel()
        viewModel.setup(with: ServicePlanDataService.currentSubscription)
        controller.viewModel = viewModel
        return controller
    }
    
    enum Destination {
        case details(of: ServicePlan)
        case buyMore
    }
}
