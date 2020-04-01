//
//  SignInCoordinator.swift
//  ProtonMail - Created on 8/20/19.
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


class AccountPasswordCoordinator: DefaultCoordinator {
    typealias VC = AccountPasswordViewController
    
    weak var viewController: VC?
    let viewModel : SignInViewModel
    var services: ServiceFactory
    
    var delegate: CoordinatorDelegate? = nil
    
    init?(vc: UIViewController, vm: SignInViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
        guard let viewC = vc as? VC else {
            return nil
        }
        self.viewController = viewC
        self.viewModel = vm
        self.services = services
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    func stop() {
        delegate?.willStop(in: self)
        
        if self.viewController?.presentingViewController != nil {
            self.viewController?.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.viewController?.navigationController?.popViewController(animated: true)
        }
        
        delegate?.didStop(in: self)
    }
}
