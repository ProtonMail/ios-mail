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


class AccountManagerCoordinator: DefaultCoordinator {
    typealias VC = AccountManagerViewController
    
    weak var viewController: VC?
    let viewModel : AccountManagerViewModel
    var services: ServiceFactory
    
    var delegate: CoordinatorDelegate? = nil
    
    enum Destination : String {
        case addAccount = "toAddAccountSegue"
    }
    
    init?(nav: UINavigationController, vm: AccountManagerViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
        guard let next = nav.firstViewController() as? VC else {
            return nil
        }
        self.viewController = next
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
    
    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        default:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        }
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        switch dest {
        case .addAccount:
            let preFilledUsername = (sender as? UsersManager.DisconnectedUserHandle)?.defaultEmail
            guard let account = AccountConnectCoordinator(vc: destination,
                                                          vm: SignInViewModel(usersManager: self.services.get(), username: preFilledUsername),
                                                          services: self.services) else {
                return false
            }
            account.delegate = self
            account.start()
            return true
        default:
            return false
        }
    }
}

extension AccountManagerCoordinator: CoordinatorDelegate {
    func willStop(in coordinator: CoordinatorNew) {
        
    }
    
    func didStop(in coordinator: CoordinatorNew) {
        self.stop()
    }
}
