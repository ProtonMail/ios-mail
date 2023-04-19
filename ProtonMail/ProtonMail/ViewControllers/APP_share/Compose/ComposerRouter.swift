// Copyright (c) 2022 Proton Technologies AG
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

final class ComposerRouter {
    private var navigationController: UINavigationController?

    init() {}

    func setupNavigation(_ nav: UINavigationController) {
        self.navigationController = nav
    }

    func navigateToPasswordSetupView(
        password: String,
        confirmPassword: String,
        passwordHint: String,
        delegate: ComposePasswordDelegate
    ) {
        let viewController = ComposePasswordVC.instance(
            password: password,
            confirmPassword: confirmPassword,
            hint: passwordHint,
            delegate: delegate
        )
        navigationController?.show(viewController, sender: nil)
    }

    func navigateToExpirationSetupView(
        expirationTimeInterval: TimeInterval,
        delegate: ComposeExpirationDelegate
    ) {
        let viewController = ComposeExpirationVC(
            expiration: expirationTimeInterval,
            delegate: delegate
        )
        navigationController?.show(viewController, sender: nil)
    }
}
