//
//  PinCodeSetUpViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

class PinCodeSetUpViewController: ProtonMailViewController {
    private enum Error {
        case pinTooShort
        case pinTooLong

        var errorMessage: String {
            switch self {
            case .pinTooShort:
                return LocalString._pin_code_setup1_textfield_pin_too_short
            case .pinTooLong:
                return LocalString._pin_code_setup1_textfield_pin_too_long
            }
        }
    }

    @IBOutlet private weak var passwordTextField: PMTextField!
    @IBOutlet private weak var nextButton: ProtonButton!

    var viewModel: PinCodeViewModel?
    var coordinator: PinCodeSetupCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBar()

        title = LocalString._pin_code_setup1_title

        view.backgroundColor = ColorProvider.BackgroundNorm

        passwordTextField.delegate = self
        passwordTextField.isPassword = true
        passwordTextField.title = LocalString._pin_code_setup1_textfield_title
        passwordTextField.allowOnlyNumbers = true
        passwordTextField.assistiveText = LocalString._pin_code_setup1_textfield_assistiveText

        nextButton.setMode(mode: .solid)
        nextButton.setTitle(LocalString._pin_code_setup1_button_title, for: .normal)

        let item = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(self.dismissView))
        navigationItem.leftBarButtonItem = item
        self.emptyBackButtonTitleForNextView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.reset()

        _ = passwordTextField.becomeFirstResponder()
    }

    @IBAction func nextButtonClicked(_ sender: Any) {
        hideError()

        let password = passwordTextField.value
        var error: PinCodeSetUpViewController.Error?
        if password.count < 4 {
            error = password.count < 4 ? .pinTooShort : nil
        } else if password.count > 21 {
            error = .pinTooLong
        }

        if let validationError = error {
            showError(error: validationError)
        } else {
            _ = viewModel?.setCode(passwordTextField.value)
            coordinator?.go(to: .step2)
        }
    }

    @objc
    private func dismissView() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    private func showError(error: PinCodeSetUpViewController.Error) {
        passwordTextField.isError = true
        passwordTextField.errorMessage = error.errorMessage
    }

    private func hideError() {
        passwordTextField.isError = false
        passwordTextField.errorMessage = nil
    }
}

extension PinCodeSetUpViewController: PMTextFieldDelegate {
    func didEndEditing(textField: PMTextField) {}

    func didChangeValue(_ textField: PMTextField, value: String) {
        hideError()
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool { true }

    func didBeginEditing(textField: PMTextField) {}
}
