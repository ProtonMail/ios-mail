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
    case changePinCode = "change_pinCode"
    case pinCodeDisable = "pincode_disable"
}

// sourcery: mock
protocol SettingsLockRouterProtocol {
    func go(to dest: SettingsLockRouterDestination)
}

final class SettingsLockRouter: SettingsLockRouterProtocol {
    typealias Dependencies = SettingsLockViewModel.Dependencies & PinCodeSetupRouter.Dependencies

    private weak var navigationController: UINavigationController?
    private let dependencies: Dependencies

    init(navigationController: UINavigationController?, dependencies: Dependencies) {
        self.dependencies = dependencies
        self.navigationController = navigationController
    }

    func start() {
        let viewModel = SettingsLockViewModel(router: self, dependencies: dependencies)
        let viewController = SettingsLockViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    func go(to dest: SettingsLockRouterDestination) {
        let step: PinCodeSetupRouter.PinCodeSetUpStep
        switch dest {
        case .pinCodeSetup:
            step = .enterNewPinCode
        case .changePinCode:
            step = .confirmBeforeChanging
        case .pinCodeDisable:
            step = .confirmBeforeDisabling
        }

        let nav = UINavigationController()
        nav.modalPresentationStyle = .fullScreen

        let router = PinCodeSetupRouter(navigationController: nav, dependencies: dependencies)
        router.start(step: step)
        navigationController?.present(nav, animated: true, completion: nil)
    }
}
