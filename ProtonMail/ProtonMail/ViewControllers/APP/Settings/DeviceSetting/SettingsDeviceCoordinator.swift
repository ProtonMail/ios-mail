//
//  SettingsDeviceCoordinator.swift
//  Proton Mail - Created on 12/12/18.
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

import ProtonCore_Keymaker
import UIKit

class SettingsDeviceCoordinator {
    enum Destination: String {
        case accountSetting = "settings_account_settings"
        case autoLock = "settings_auto_lock"
        case combineContact = "settings_combine_contact"
        case alternativeRouting = "settings_alternative_routing"
        case swipeAction = "settings_swipe_action"
        case darkMode = "settings_dark_mode"
    }

    // TODO: dependencies should only include a factory
    typealias Dependencies = SettingsAccountCoordinator.Dependencies

    private let userManager: UserManager
    private let services: ServiceFactory
    private let dependencies: Dependencies

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?,
         user: UserManager,
         services: ServiceFactory,
         dependencies: Dependencies) {
        self.navigationController = navigationController
        self.userManager = user
        self.services = services
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = SettingsDeviceViewModel(
            user: userManager,
            biometricStatus: UIDevice.current,
            lockCacheStatus: services.get(by: Keymaker.self),
            dependencies: .init(cleanCache: CleanCache(dependencies: .init(usersManager: dependencies.usersManager)))
        )

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
        let accountSettings = SettingsAccountCoordinator(
            navigationController: self.navigationController,
            dependencies: dependencies
        )
        accountSettings.start(animated: deepLink == nil)
        accountSettings.follow(deepLink: deepLink)
    }

    private func openAutoLock() {
        let lockSetting = SettingsLockRouter(navigationController: self.navigationController, coreKeyMaker: services.get())
        lockSetting.start()
    }

    private func openCombineContacts() {
        let viewModel = ContactCombineViewModel(combineContactCache: services.userCachedStatus)
        let viewController = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.show(viewController, sender: nil)
    }

    private func openAlternativeRouting() {
        let viewModel = NetworkSettingViewModel(
            userCache: services.userCachedStatus,
            dohSetting: BackendConfiguration.shared.doh
        )
        let controller = SwitchToggleViewController(viewModel: viewModel)
        navigationController?.show(controller, sender: nil)
    }

    private func openGesture() {
        let apiServices = dependencies.usersManager.users.map(\.apiService)
        guard !apiServices.isEmpty else {
            return
        }
        let coordinator = SettingsGesturesCoordinator(
            navigationController: self.navigationController,
            userInfo: userManager.userInfo,
            apiServices: apiServices,
            swipeActionCache: services.userCachedStatus
        )
        coordinator.start()
    }

    private func openDarkMode() {
        let viewModel = DarkModeSettingViewModel(darkModeCache: services.userCachedStatus)
        let viewController = SettingsSingleCheckMarkViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func openToolbarCustomizationView() {
        let viewModel = ToolbarSettingViewModel(
            infoBubbleViewStatusProvider: services.userCachedStatus,
            toolbarActionProvider: userManager,
            saveToolbarActionUseCase: SaveToolbarActionSettings(
                dependencies: .init(user: userManager)
            )
        )
        let viewController = ToolbarSettingViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func openApplicationLogsView() {
        let viewModel = ApplicationLogsViewModel()
        let viewController = ApplicationLogsViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension DeepLink.Node {
    static let accountSetting = DeepLink.Node(name: "settings_account_settings")
}
