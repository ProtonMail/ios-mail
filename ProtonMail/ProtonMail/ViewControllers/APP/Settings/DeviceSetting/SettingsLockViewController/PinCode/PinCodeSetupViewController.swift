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

import ProtonCoreUIFoundations
import UIKit

final class PinCodeSetupViewController: ProtonMailViewController {
    private let customView = PinCodeSetupView()
    private let viewModel: PinCodeSetupVMProtocol
    private var step: PinCodeSetupRouter.PinCodeSetUpStep

    override func loadView() {
        view = customView
    }

    init(viewModel: PinCodeSetupVMProtocol, step: PinCodeSetupRouter.PinCodeSetUpStep) {
        self.viewModel = viewModel
        self.step = step
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        setUpView()
        customView.confirmationButton.addTarget(
            self,
            action: #selector(self.clickConfirmButton),
            for: .touchUpInside
        )
    }
}

// MARK: - View setup
extension PinCodeSetupViewController {
    private func setUpView() {
        switch step {
        case .enterNewPinCode:
            title = L10n.PinCodeSetup.setPinCode
            setupPasswordTextField(
                title: L10n.PinCodeSetup.enterNewPinCode,
                assistiveText: L10n.PinCodeSetup.enterNewPinCodeAssistiveText
            )
            customView.confirmationButton.setTitle(LocalString._genernal_continue, for: .normal)

            setUpNavigationBar()
        case .repeatPinCode:
            title = L10n.PinCodeSetup.repeatPinCode
            setupPasswordTextField(title: L10n.PinCodeSetup.repeatPinCode)
            customView.confirmationButton.setTitle(LocalString._general_confirm_action, for: .normal)
        case .confirmBeforeChanging:
            title = L10n.PinCodeSetup.changePinCode
            setupPasswordTextField(title: L10n.PinCodeSetup.enterOldPinCode)
            customView.confirmationButton.setTitle(LocalString._general_confirm_action, for: .normal)

            setUpNavigationBar()
        case .confirmBeforeDisabling:
            title = L10n.PinCodeSetup.disablePinCode
            setupPasswordTextField(title: L10n.PinCodeSetup.enterOldPinCode)
            customView.confirmationButton.setTitle(LocalString._general_confirm_action, for: .normal)

            setUpNavigationBar()
        }
    }

    private func setupPasswordTextField(title: String, assistiveText: String? = nil) {
        customView.passwordTextField.delegate = self
        customView.passwordTextField.isPassword = true
        customView.passwordTextField.title = title
        customView.passwordTextField.allowOnlyNumbers = true
        customView.passwordTextField.assistiveText = assistiveText
        _ = customView.passwordTextField.becomeFirstResponder()
    }

    private func setUpNavigationBar() {
        let item = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(self.dismissPinScreen))
        navigationItem.leftBarButtonItem = item
        emptyBackButtonTitleForNextView()
    }

    private func hideTextFieldError() {
        customView.passwordTextField.isError = false
        customView.passwordTextField.errorMessage = nil
    }

    @MainActor
    private func showPinCodeError(error: Error) {
        customView.passwordTextField.isError = true
        customView.passwordTextField.errorMessage = error.localizedDescription
    }

    @MainActor
    @objc
    private func dismissPinScreen() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - Functions
extension PinCodeSetupViewController {
    @objc
    private func clickConfirmButton() {
        let pinCode = customView.passwordTextField.value
        switch step {
        case .enterNewPinCode:
            do {
                try viewModel.isValid(pinCode: pinCode)
                viewModel.set(newPinCode: pinCode)
                viewModel.go(to: .repeatPinCode)
            } catch {
                showPinCodeError(error: error)
            }
        case .repeatPinCode:
            do {
                try viewModel.isNewPinCodeMatch(repeatPinCode: pinCode)
                Task {
                    if await viewModel.activatePinCodeProtection() {
                        dismissPinScreen()
                    }
                }
            } catch {
                showPinCodeError(error: error)
            }
        case .confirmBeforeChanging:
            Task {
                do {
                    try await viewModel.isCorrectCurrentPinCode(pinCode)
                    await MainActor.run(body: {
                        self.viewModel.go(to: .enterNewPinCode)
                    })
                } catch {
                    showPinCodeError(error: error)
                }
            }
        case .confirmBeforeDisabling:
            Task {
                do {
                    try await viewModel.isCorrectCurrentPinCode(pinCode)
                    await MainActor.run(body: {
                        self.viewModel.deactivatePinCodeProtection()
                        self.dismissPinScreen()
                    })
                } catch {
                    showPinCodeError(error: error)
                }
            }
        }
    }
}

extension PinCodeSetupViewController: PMTextFieldDelegate {
    func didEndEditing(textField: ProtonCoreUIFoundations.PMTextField) { }

    func textFieldShouldReturn(_ textField: ProtonCoreUIFoundations.PMTextField) -> Bool { true }

    func didBeginEditing(textField: ProtonCoreUIFoundations.PMTextField) { }

    func didChangeValue(_ textField: PMTextField, value: String) {
        hideTextFieldError()
    }
}
