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
