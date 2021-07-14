//
//  StorefrontCoordinator.swift
//  ProtonMail - Created on 18/12/2018.
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_PaymentsUI
import ProtonCore_UIFoundations
import SideMenuSwift
import UIKit

class StorefrontCoordinator {

    private weak var sideMenu: SideMenuProtocol?
    private let paymentsUI: PaymentsUIProtocol
    private let eventsService: EventsFetching

    init(paymentsUI: PaymentsUIProtocol, sideMenu: SideMenuProtocol, eventsService: EventsFetching) {
        self.paymentsUI = paymentsUI
        self.sideMenu = sideMenu
        self.eventsService = eventsService
    }

    func handle(navigationAction: StorefrontNavigationAction) {
        switch navigationAction {
        case .menuTapped:
            sideMenu?.revealMenu(animated: true, completion: nil)
        }
    }

    func start() {
        let viewController = StorefrontViewController(
            coordinator: self,
            paymentsUI: paymentsUI,
            eventsService: eventsService
        )
        let navigationController = createNavigationController(with: viewController)
        sideMenu?.setContentViewController(to: navigationController, animated: false, completion: nil)
        sideMenu?.hideMenu(animated: true, completion: nil)
    }

    private func createNavigationController(with rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.navigationBar.titleTextAttributes = FontManager.DefaultStrong
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = false
        return navigationController
    }

}
