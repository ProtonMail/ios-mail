//
//  SharePinUnlockCoordinator.swift
//  Share - Created on 11/4/18.
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

class SharePinUnlockCoordinator : ModalCoordinator {
    typealias VC = SharePinUnlockViewController
    
    var services: ServiceFactory
    
    weak var destinationNavigationController: UINavigationController?
    weak var navigationController: UINavigationController?
    
    var viewController: SharePinUnlockViewController?
    let viewModel: PinCodeViewModel
    lazy var configuration: ((VC) -> ())? = { [unowned self] vc in
        vc.viewModel = self.viewModel
    }
    
    init(navigation : UINavigationController, vm: PinCodeViewModel, services: ServiceFactory, delegate: SharePinUnlockViewControllerDelegate) {
        //parent navigation
        self.navigationController = navigation
        self.viewModel = vm
        self.services = services
        //create self view controller
        self.viewController = SharePinUnlockViewController(nibName: "SharePinUnlockViewController", bundle: nil)
        self.viewController?.delegate = delegate
    }

}
