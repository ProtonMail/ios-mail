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
    
    enum Destination : String {
        case addAccount = "toAddAccountSegue"
        case mailbox   = "toMailboxSegue"
        case label     = "toLabelboxSegue"
        case settings  = "toSettingsSegue"
        case bugs      = "toBugsSegue"
        case contacts  = "toContactsSegue"
        case feedbacks = "toFeedbackSegue"
        case plan      = "toServicePlan"
        
        init?(rawValue: String) {
            switch rawValue {
            case "toAddAccountSegue": self = .addAccount
            case "toMailboxSegue", String(describing: MailboxViewController.self): self = .mailbox
            case "toLabelboxSegue": self = .label
            case "toSettingsSegue": self = .settings
            case "toBugsSegue": self = .bugs
            case "toContactsSegue": self = .contacts
            case "toFeedbackSegue": self = .feedbacks
            case "toServicePlan": self = .plan
            default: return nil
            }
        }
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
    
    func follow(_ deepLink: DeepLink) {
        if let path = deepLink.popFirst, let dest = MenuCoordinatorNew.Destination(rawValue: path.name) {
            switch dest {
            default:
                self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: deepLink)
            }
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
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        switch dest {
        case .addAccount:
            guard let account = AccountConnectCoordinator(vc: destination,
                                                          vm: SignInViewModel(usersManager: self.services.get()),
                                                          services: self.services) else {
                return false
            }
            account.start()
            return true
        default:
            return false
        }
    }
}
