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

class SignInCoordinator: DefaultCoordinator {
    typealias VC = SignInViewController
    
    weak var viewController: VC?
    let viewModel : SignInViewModel
    var services: ServiceFactory
    
    enum Destination : String {
        case mailbox   = "toMailboxSegue"
        case label     = "toLabelboxSegue"
        case settings  = "toSettingsSegue"
        case bugs      = "toBugsSegue"
        case contacts  = "toContactsSegue"
        case feedbacks = "toFeedbackSegue"
        case plan      = "toServicePlan"
        
        init?(rawValue: String) {
            switch rawValue {
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
    
    init(destination: UIWindow, vm: SignInViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.services = services
        
        // defined by Storyboard
        let controller = (destination.rootViewController as! UINavigationController).viewControllers.first as! VC
        
        self.viewController = controller
        self.viewController?.modalPresentationStyle = .fullScreen
    }
    
    func start() {
        self.viewController?.set(viewModel: self.viewModel)
        self.viewController?.set(coordinator: self)
    }
    
    internal func follow(_ deepLink: DeepLink) {
        // FIXME: does this make sense? do we ever get here?
        if let path = deepLink.popFirst, let dest = MenuCoordinatorNew.Destination(rawValue: path.name) {
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: deepLink)
        }
    }
    
    ///TODO::fixme. add warning or error when return false except the last one.
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        
        return false
    }
}
