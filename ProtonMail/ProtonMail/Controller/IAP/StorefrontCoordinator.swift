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
import SWRevealViewController

class StorefrontCoordinator: PushCoordinator {
    var configuration: ((StorefrontCollectionViewController) -> ())?
    
    var services: ServiceFactory = sharedServices
    
    typealias VC = StorefrontCollectionViewController
    weak var viewController: StorefrontCollectionViewController?
    var navigationController: UINavigationController?
    weak var rvc: SWRevealViewController?
    var user: UserManager
    
    init(navigation: UINavigationController, user: UserManager) {
        self.navigationController = navigation
        let vc = UIStoryboard(name: "ServiceLevel", bundle: .main).make(StorefrontCollectionViewController.self)
        self.viewController = vc
        self.user = user
    }
    
    init(rvc: SWRevealViewController?, user: UserManager) {
        self.rvc = rvc
        let vc = UIStoryboard(name: "ServiceLevel", bundle: .main).make(StorefrontCollectionViewController.self)
        self.viewController = vc
        self.user = user
        self.navigationController = UINavigationController(rootViewController: vc)
    }
    
    func go(to nextPlan: ServicePlan) {
        guard let navigationController = self.navigationController else { return }
        let nextCoordinator = StorefrontCoordinator(navigation: navigationController, user: self.user)
        let storefront = Storefront(plan: nextPlan, servicePlanService: user.sevicePlanService, user: user.userInfo)
        nextCoordinator.viewController?.viewModel = StorefrontViewModel(storefront: storefront, servicePlanService: user.sevicePlanService)

        nextCoordinator.start()
    }
    
    func goToBuyMoreCredits(for subscription: ServicePlanSubscription) {
        guard let navigationController = self.navigationController else { return }
        let nextCoordinator = StorefrontCoordinator(navigation: navigationController, user: self.user)
        let storefront = Storefront(creditsFor: subscription, servicePlanService: user.sevicePlanService, user: user.userInfo)
        nextCoordinator.viewController?.viewModel = StorefrontViewModel(storefront: storefront, servicePlanService: user.sevicePlanService)

        nextCoordinator.start()
    }
    
    private var observation: NSKeyValueObservation!
    func start() {
        self.viewController?.set(coordinator: self)
        if self.navigationController != nil, self.rvc != nil {
            if let child = self.viewController {
                let menuButton = UIBarButtonItem(image: UIImage(named: "hamburger")!, style: .plain, target: nil, action: nil)
                observation = self.navigationController?.observe(\UINavigationController.parent) { (controller, change) in
                    ProtonMailViewController.setup(child, menuButton, true)
                    self.observation = nil
                }
            }
            self.rvc?.pushFrontViewController(self.navigationController, animated: true)
        } else if let vc = self.viewController {
            navigationController?.pushViewController(vc, animated: animated)
        }
    }
}
