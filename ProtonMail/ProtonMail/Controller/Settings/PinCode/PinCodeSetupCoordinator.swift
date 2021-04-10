//
//  PinCodeSetupCoordinator.swift
//  ProtonMail
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
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

class PinCodeSetupCoordinator: PushCoordinator {
    enum Destination: String {
        case step2 = "setting_pin_code_step2"
    }

    var viewController: PinCodeSetUpViewController?
    let pinCodeSetupViewModel: SetPinCodeModelImpl?
    var services: ServiceFactory

    var configuration: ((PinCodeSetUpViewController) -> Void)?

    var navigationController: UINavigationController?

    init(nav: UINavigationController, services: ServiceFactory, scene: AnyObject? = nil) {
        self.navigationController = nav
        self.services = services
        self.viewController = PinCodeSetUpViewController(nibName: "PinCodeSetUpViewController", bundle: nil)
        self.pinCodeSetupViewModel = SetPinCodeModelImpl()
        self.viewController?.viewModel = self.pinCodeSetupViewModel
    }

    func start() {
        if let viewController = self.viewController {
            self.viewController?.coordinator = self
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func go(to dest: Destination) {
        switch dest {
        case .step2:
            let controller = PinCodeConfirmationViewController(nibName: "PinCodeConfirmationViewController",
                                                               bundle: nil)
            controller.viewModel = self.pinCodeSetupViewModel
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}
