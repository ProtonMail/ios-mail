//
//  ContactTabBarCoordinator.swift
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
import SideMenuSwift

class ContactTabBarCoordinator: DefaultCoordinator {
    typealias VC = ContactTabBarViewController
    
    internal weak var viewController: ContactTabBarViewController?
    internal weak var sideMenu: SideMenuController?
    
    var services: ServiceFactory
    private var user: UserManager
    
    init(sideMenu: SideMenuController?, vc: ContactTabBarViewController, services: ServiceFactory, user: UserManager, deeplink: DeepLink? = nil) {
        self.user = user
        self.sideMenu = sideMenu
        self.viewController = vc
        self.services = services
    }
    
    func start() {
        self.viewController?.set(coordinator: self)
        
        /// setup contacts vc
        if let viewController = viewController?.contactsViewController {
            let vmService = sharedVMService
            vmService.contactsViewModel(viewController, user: self.user)
        }
        
        /// setup contact groups view controller
        if let viewController = viewController?.groupsViewController {
            let vmService = sharedVMService
            vmService.contactGroupsViewModel(viewController, user: self.user)
        }
        
        if let vc = self.viewController {
            self.sideMenu?.setContentViewController(to: vc)
            self.sideMenu?.hideMenu()
        }
    }
}
