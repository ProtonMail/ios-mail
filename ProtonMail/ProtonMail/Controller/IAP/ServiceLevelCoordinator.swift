//
//  ServiceLevelCoordinator.swift
//  ProtonMail - Created on 08/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
