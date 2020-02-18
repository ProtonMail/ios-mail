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


class AccountConnectCoordinator: DefaultCoordinator {
    typealias VC = AccountConnectViewController
    
    weak var viewController: VC?
    let viewModel : SignInViewModel
    var services: ServiceFactory
    
    enum Destination : String {
        case signUp = "toSignUpSegue"
    }
    
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
    
    func follow(_ deepLink: DeepLink) {
        if let path = deepLink.popFirst, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: deepLink)
        }
    }
    
    //old one call from vc
    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        default:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        }
    }
    
    ///TODO::fixme. add warning or error when return false except the last one.
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        switch Destination(rawValue: identifier ?? "") {
        case .some(.signUp):
            let viewController = destination as! SignUpUserNameViewController
            let deviceCheckToken = sender as? String ?? ""
            viewController.viewModel = SignupViewModelImpl(token: deviceCheckToken)
            return true
        default:
            return false
        }
    }
}
