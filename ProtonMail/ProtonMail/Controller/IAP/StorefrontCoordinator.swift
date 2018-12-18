//
//  StorefrontCoordinator.swift
//  ProtonMail - Created on 18/12/2018.
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
    

import UIKit

class StorefrontCoordinator: PushCoordinator {
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
            let storefront = Storefront.init(plan: nextPlan)
            controller.viewModel = StorefrontViewModel(storefront: storefront)
        }
        nextCoordinator.start()
    }
    
    func goToBuyMoreCredits() {
        // TODO: implement
    }
}
