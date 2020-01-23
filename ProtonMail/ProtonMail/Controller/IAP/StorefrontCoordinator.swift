//
//  StorefrontCoordinator.swift
//  ProtonMail - Created on 18/12/2018.
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
    

import UIKit

class StorefrontCoordinator: PushCoordinator {
    var services: ServiceFactory = sharedServices
    
    typealias VC = StorefrontCollectionViewController
    weak var viewController: StorefrontCollectionViewController?
    weak var navigationController: UINavigationController?
    var configuration: ((VC)->Void)?
    
    init(navigation: UINavigationController,
         config: @escaping (VC)->Void )
    {
        self.navigationController = navigation
        self.configuration = config
        self.viewController = UIStoryboard(name: "ServiceLevel", bundle: .main).make(StorefrontCollectionViewController.self)
    }
    
    func go(to nextPlan: ServicePlan) {
        guard let navigationController = self.navigationController else { return }
        let nextCoordinator = StorefrontCoordinator(navigation: navigationController) { controller in
            let user = self.services.get(by: UsersManager.self).firstUser!
            let storefront = Storefront(plan: nextPlan, servicePlanService: user.sevicePlanService, user: user.userInfo)
            controller.viewModel = StorefrontViewModel(storefront: storefront, servicePlanService: user.sevicePlanService)
        }
        nextCoordinator.start()
    }
    
    func goToBuyMoreCredits(for subscription: ServicePlanSubscription) {
        guard let navigationController = self.navigationController else { return }
        let nextCoordinator = StorefrontCoordinator(navigation: navigationController) { controller in
            let user = self.services.get(by: UsersManager.self).firstUser!
            let storefront = Storefront(creditsFor: subscription, servicePlanService: user.sevicePlanService, user: user.userInfo)
            controller.viewModel = StorefrontViewModel(storefront: storefront, servicePlanService: user.sevicePlanService)
        }
        nextCoordinator.start()
    }
}
