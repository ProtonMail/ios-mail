//
//  SettingsDeviceCoordinator.swift
//  ProtonMail - Created on 12/12/18.
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
import ProtonCore_Common

class SettingsDeviceCoordinator {
    enum Destination: String {
        case accountSetting = "settings_account_settings"
        case autoLock       = "settings_auto_lock"
        case combineContact = "settings_combine_contact"
        case alternativeRouting = "settings_alternative_routing"
        case swipeAction = "settings_swipe_action"
        case darkMode = "settings_dark_mode"
    }

    private let services: ServiceFactory

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?, services: ServiceFactory) {
        self.navigationController = navigationController
        self.services = services
    }

    func start() {
        let usersManager = services.get(by: UsersManager.self)
        guard let user = usersManager.firstUser else {
            return
        }

        let viewModel = SettingsDeviceViewModelImpl(user: user,
                                             users: usersManager,
                                             dohSetting: DoHMail.default,
                                             biometricStatus: UIDevice.current)

        let viewController = SettingsDeviceViewController(viewModel: viewModel, coordinator: self)
        navigationController?.pushViewController(viewController, animated: false)
    }

    func go(to dest: Destination, deepLink: DeepLink? = nil) {
        switch dest {
        case .accountSetting:
            openAccount(deepLink: deepLink)
        case .autoLock:
            openAutoLock()
        case .combineContact:
            openCombineContacts()
        case .alternativeRouting:
            openAlternativeRouting()
        case .swipeAction:
            openGesture()
        case .darkMode:
            openDarkMode()
        }
    }

    func follow(deepLink: DeepLink?) {
        guard let link = deepLink, let node = link.popFirst else {
            return
        }
        guard let destination = Destination(rawValue: node.name) else {
            return
        }
        go(to: destination, deepLink: link)
    }

    private func openAccount(deepLink: DeepLink?) {
        let accountSettings = SettingsAccountCoordinator(navigationController: self.navigationController, services: self.services)
        accountSettings.start(animated: deepLink == nil)
        accountSettings.follow(deepLink: deepLink)
    }

    private func openAutoLock() {
        let lockSetting = SettingsLockCoordinator(navigationController: self.navigationController, services: self.services)
        lockSetting.start()
    }

    private func openCombineContacts() {
        let viewModel = SettingsCombineContactViewModel(combineContactCache: userCachedStatus)
        let viewController = SettingsContactCombineViewController(viewModel: viewModel, coordinator: self)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func openAlternativeRouting() {
        let controller = SettingsNetworkTableViewController(nibName: "SettingsNetworkTableViewController", bundle: nil)
        controller.viewModel = SettingsNetworkViewModel(userCache: userCachedStatus, dohSetting: DoHMail.default)
        controller.coordinator = self
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func openGesture() {
        let coordinator = SettingsGesturesCoordinator(navigationController: self.navigationController)
        coordinator.start()
    }

    private func openDarkMode() {
        let viewModel = SettingsDarkModeViewModel(darkModeCache: userCachedStatus)
        let viewController = SettingsDarkModeViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension DeepLink.Node {
    static let accountSetting = DeepLink.Node.init(name: "settings_account_settings")
}
