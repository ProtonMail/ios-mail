//
//  SettingsLockCoordinator.swift
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

import UIKit

enum SettingsLockRouterDestination: String {
    case pinCodeSetup = "pincode_setup"
}

// sourcery: mock
protocol SettingsLockRouterProtocol {
    func go(to dest: SettingsLockRouterDestination)
}

final class SettingsLockRouter: SettingsLockRouterProtocol {
    private weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = SettingsLockViewModel(router: self, dependencies: .init(biometricStatus: UIDevice.current))
        let viewController = SettingsLockViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func go(to dest: SettingsLockRouterDestination) {
        switch dest {
        case .pinCodeSetup:
            let nav = UINavigationController()
            nav.modalPresentationStyle = .fullScreen
            let coordinator = PinCodeSetupCoordinator(nav: nav)
            coordinator.start()
            self.navigationController?.present(nav, animated: true, completion: nil)
        }
    }
}
