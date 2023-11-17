// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import UIKit

// sourcery: mock
protocol PinCodeSetupRouterProtocol {
    func go(to step: PinCodeSetupRouter.PinCodeSetUpStep, existingVM: PinCodeSetupViewModel)
}

final class PinCodeSetupRouter: PinCodeSetupRouterProtocol {
    typealias Dependencies = PinCodeSetupViewModel.Dependencies

    enum PinCodeSetUpStep {
        case enterNewPinCode, repeatPinCode, confirmBeforeChanging, confirmBeforeDisabling
    }

    private weak var navigationController: UINavigationController?
    private let dependencies: PinCodeSetupViewModel.Dependencies

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start(step: PinCodeSetUpStep) {
        let viewModel = PinCodeSetupViewModel(
            dependencies: dependencies,
            router: self
        )
        let viewController = PinCodeSetupViewController(viewModel: viewModel, step: step)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func go(to step: PinCodeSetUpStep, existingVM: PinCodeSetupViewModel) {
        let viewController = PinCodeSetupViewController(viewModel: existingVM, step: step)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
