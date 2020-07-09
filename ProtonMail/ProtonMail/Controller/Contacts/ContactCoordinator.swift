//
//  ContactCoordinator.swift
//  ProtonMail - Created on 12/13/18.
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
import SWRevealViewController

class ContactCoordinator : DefaultCoordinator {
    typealias VC = ContactsViewController
    
    let viewModel : ContactsViewModel
    var services: ServiceFactory
    
    internal weak var navigation: UIViewController?
    internal weak var swRevealVC: SWRevealViewController?
    internal weak var viewController: ContactsViewController?
    
    ///
    internal weak var lastestCoordinator: CoordinatorNew?
    
    func start() {
        
    }
    ///
    enum Destination : String {
        case test   = ""
    }
    
    init(rvc: SWRevealViewController?, nav: UIViewController?, vc: ContactsViewController, vm: ContactsViewModel, services: ServiceFactory, deeplink: DeepLink? = nil) {
        self.navigation = nav
        self.swRevealVC = rvc
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }
    
    func go(to dest: Destination, sender: Any? = nil) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
    }
    
    func follow(_ deepLink: DeepLink) {
        
    }
    
    ///TODO::fixme. add warning or error when return false except the last one.
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        return false
    }
}
