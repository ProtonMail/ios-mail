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

import Foundation
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

final class PinCodeSetupView: UIView, AccessibleView {
    let passwordTextField = SubViewsFactory.passwordTextField()
    let confirmationButton = SubViewsFactory.confirmationButton()

    init() {
        super.init(frame: .zero)
        addSubViews()
        setupLayout()
        backgroundColor = ColorProvider.BackgroundNorm
        generateAccessibilityIdentifiers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubViews() {
        addSubview(passwordTextField)
        addSubview(confirmationButton)
    }

    private func setupLayout() {
        [
            passwordTextField.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            passwordTextField.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor,
                constant: 128
            ),
            passwordTextField.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            )
        ].activate()

        [
            confirmationButton.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            confirmationButton.topAnchor.constraint(
                equalTo: passwordTextField.bottomAnchor,
                constant: 16
            ),
            confirmationButton.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            )
        ].activate()
    }
}

private enum SubViewsFactory {
    static func passwordTextField() -> PMTextField {
        let textField = PMTextField()
        return textField
    }

    static func confirmationButton() -> ProtonButton {
        let button = ProtonButton()
        button.setMode(mode: .solid)
        return button
    }
}
