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

import ProtonCoreKeymaker
import UIKit

class SettingsDeviceCoordinator {
    enum Destination: String {
        case accountSetting = "settings_account_settings"
        case autoLock = "settings_auto_lock"
        case combineContact = "settings_combine_contact"
        case alternativeRouting = "settings_alternative_routing"
        case contactsSettings = "settings_contacts"
        case swipeAction = "settings_swipe_action"
        case darkMode = "settings_dark_mode"
        case messageSwipeNavigation = "settings_message_swipe_navigation"
        case scanQRCode = "settings_scan_qr_code"
    }

    typealias Dependencies = HasSettingsViewsFactory
    & HasToolbarSettingViewFactory
    & SettingsAccountCoordinator.Dependencies
    & SettingsLockRouter.Dependencies
    & ContactsSettingsViewModel.Dependencies

    private let dependencies: Dependencies

    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?,
         dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewController = dependencies.settingsViewsFactory.makeDeviceView(coordinator: self)
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
        case .contactsSettings:
            openContactsSettings()
        case .swipeAction:
            openGesture()
        case .darkMode:
            openDarkMode()
        case .messageSwipeNavigation:
            openMessageSwipeNavigationSetting()
        case .scanQRCode:
            openScanQRCodeInstructionsView()
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
        let lockSetting = SettingsLockRouter(navigationController: navigationController, dependencies: dependencies)
        lockSetting.start()
    }

    private func openCombineContacts() {
        let viewController = dependencies.settingsViewsFactory.makeContactCombineView()
        navigationController?.show(viewController, sender: nil)
    }

    private func openAlternativeRouting() {
        let controller = dependencies.settingsViewsFactory.makeNetworkSettingView()
        navigationController?.show(controller, sender: nil)
    }

    private func openContactsSettings() {
        let viewModel = ContactsSettingsViewModel(dependencies: dependencies)
        let viewController = ContactsSettingsViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openGesture() {
        let coordinator = SettingsGesturesCoordinator(
            navigationController: navigationController,
            dependencies: dependencies
        )
        coordinator.start()
    }

    private func openDarkMode() {
        let viewController = dependencies.settingsViewsFactory.makeDarkModeSettingView()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func openMessageSwipeNavigationSetting() {
        let viewController = dependencies.settingsViewsFactory.makeMessageSwipeNavigationView()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func openToolbarCustomizationView() {
        let viewController = dependencies.toolbarSettingViewFactory.makeSettingView()
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func openApplicationLogsView() {
        let viewController = dependencies.settingsViewsFactory.makeApplicationLogsView()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func openScanQRCodeInstructionsView() {
        Task { @MainActor in
            let viewController = dependencies.settingsViewsFactory.makeScanQRCodeInstructionsView()
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
