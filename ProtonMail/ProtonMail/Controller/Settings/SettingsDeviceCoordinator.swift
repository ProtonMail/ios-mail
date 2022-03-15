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

import Foundation
import SideMenuSwift

class SettingsDeviceCoordinator: SideMenuCoordinator {
    typealias VC = SettingsDeviceViewController

    enum Destination: String {
        case accountSetting = "settings_account_settings"
        case autoLock       = "settings_auto_lock"
        case combineContact = "settings_combine_contact"
        case alternativeRouting = "settings_alternative_routing"
        case swipeAction = "settings_swipe_action"
        case darkMode = "settings_dark_mode"
    }

    let viewModel: SettingsDeviceViewModel
    var services: ServiceFactory

    internal weak var viewController: SettingsDeviceViewController?
    internal weak var navigation: UIViewController?
    internal weak var sideMenu: SideMenuController?
    internal weak var deepLink: DeepLink?

    lazy internal var configuration: ((SettingsDeviceViewController) -> Void)? = { [unowned self] vc in
        vc.set(coordinator: self)
        vc.set(viewModel: self.viewModel)
    }

    init?(sideMenu: SideMenuController?, nav: UINavigationController,
          vm: SettingsDeviceViewModel, services: ServiceFactory, scene: AnyObject? = nil) {
        guard let next = nav.firstViewController() as? VC else {
            return nil
        }

        self.navigation = nav
        self.sideMenu = sideMenu
        self.viewController = next
        self.viewModel = vm
        self.services = services
    }

    func processDeepLink() {
        if let path = self.deepLink?.first, let dest = Destination(rawValue: path.name) {
            self.go(to: dest, sender: path.value)
        }
    }

    init(vc: SettingsDeviceViewController, vm: SettingsDeviceViewModel, services: ServiceFactory) {
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }

    init(sideMenu: SideMenuController?, nav: UIViewController?, vc: SettingsDeviceViewController, vm: SettingsDeviceViewModel, services: ServiceFactory, deeplink: DeepLink?) {
        self.navigation = nav
        self.sideMenu = sideMenu
        self.viewModel = vm
        self.viewController = vc
        self.deepLink = deeplink
        self.services = services
    }

    func go(to dest: Destination, sender: Any? = nil) {
        switch dest {
        case .alternativeRouting:
            let controller = SettingsNetworkTableViewController(nibName: "SettingsNetworkTableViewController", bundle: nil)
            controller.viewModel = SettingsNetworkViewModel(userCache: userCachedStatus, dohSetting: DoHMail.default)
            controller.coordinator = self
            self.viewController?.navigationController?.pushViewController(controller, animated: true)
        case .swipeAction:
            openGesture()
        case .darkMode:
            openDarkMode()
        default:
            self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
        }
    }

    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false
        }
        switch dest {
        case .accountSetting:
            let users: UsersManager = sharedServices.get()
            let vm = SettingsAccountViewModelImpl(user: users.firstUser!)
            guard let accountSetting = SettingsAccountCoordinator(dest: destination, vm: vm, services: self.services) else {
                return false
            }
            accountSetting.start()
            return true

        case .autoLock:
            let vm = SettingsLockViewModelImpl(biometricStatus: UIDevice.current, userCacheStatus: userCachedStatus)
            guard let lockSetting = SettingsLockCoordinator(dest: destination, vm: vm, services: self.services) else {
                return false
            }
            lockSetting.start()
            return true
        case .combineContact:
            if let vc = destination as? SettingsContactCombineViewController {
                let vm = SettingsCombineContactViewModel(combineContactCache: userCachedStatus)
                vc.set(viewModel: vm)
                vc.set(coordinator: self)
                return true
            }
            return false
        case .swipeAction:
            openGesture()
            return true
        default:
            return false
        }
    }

    private func openGesture() {
        let viewController = SettingsGesturesViewController(nibName: "SettingsGesturesViewController", bundle: nil)
        let coordinator = SettingsGesturesCoordinator(dest: viewController,
                                                      viewModel: SettingsGestureViewModelImpl(cache: userCachedStatus),
                                                      services: self.services)
        coordinator?.start()
        let navigation = UINavigationController(rootViewController: viewController)
        self.viewController?.navigationController?.present(navigation, animated: true, completion: nil)
    }

    private func openDarkMode() {
        let viewModel = SettingsDarkModeViewModel(darkModeCache: userCachedStatus)
        let viewController = SettingsDarkModeViewController(viewModel: viewModel)
        self.viewController?.navigationController?.pushViewController(viewController, animated: true)
    }
}
