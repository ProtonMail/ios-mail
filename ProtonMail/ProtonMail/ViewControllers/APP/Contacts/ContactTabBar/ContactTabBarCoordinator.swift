//
//  ContactTabBarCoordinator.swift
//  Proton Mail - Created on 12/13/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import SideMenuSwift
import UIKit

final class ContactTabBarCoordinator {
    typealias Dependencies = HasContactViewsFactory

    weak var viewController: ContactTabBarViewController?
    weak var sideMenu: SideMenuController?
    private let dependencies: Dependencies

    init(sideMenu: SideMenuController?,
         vc: ContactTabBarViewController,
         dependencies: Dependencies)
    {
        self.sideMenu = sideMenu
        self.viewController = vc
        self.dependencies = dependencies
    }

    func start() {
        self.viewController?.coordinator = self
        self.viewController?.setupViewControllers()
        if let vc = self.viewController {
            self.sideMenu?.setContentViewController(to: vc)
            self.sideMenu?.hideMenu()
        }
    }

    func makeChildViewControllers() -> [UINavigationController] {
        var result: [UINavigationController] = []
        let contactView = dependencies.contactViewsFactory.makeContactsView()
        let contactsNav = UINavigationController(rootViewController: contactView)
        result.append(contactsNav)

        let contactGroupView = dependencies.contactViewsFactory.makeGroupsView()
        let contactGroupNav = UINavigationController(rootViewController: contactGroupView)
        result.append(contactGroupNav)

        return result
    }
}
