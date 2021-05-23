//
//  PinCodeSetUpViewController.swift
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

import UIKit
import ProtonCore_UIFoundations

class PinCodeSetUpViewController: ProtonMailViewController {
    @IBOutlet private weak var passwordTextField: PMTextField!
    @IBOutlet private weak var nextButton: ProtonButton!

    var viewModel: PinCodeViewModel?
    var coordinator: PinCodeSetupCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBar()

        title = LocalString._pin_code_setup1_title
        
        view.backgroundColor = UIColorManager.BackgroundNorm

        passwordTextField.isPassword = true
        passwordTextField.title = LocalString._pin_code_setup1_textfield_title
        passwordTextField.allowOnlyNumbers = true
        passwordTextField.assistiveText = LocalString._pin_code_setup1_textfield_assistiveText

        nextButton.setMode(mode: .solid)
        nextButton.setTitle(LocalString._pin_code_setup1_button_title, for: .normal)

        let dismissBtn = #imageLiteral(resourceName: "back-arrow")
            .toUIBarButtonItem(target: self,
                               action: #selector(self.dismissView),
                               style: .done,
                               tintColor: UIColorManager.TextNorm,
                               squareSize: 24,
                               backgroundColor: nil,
                               backgroundSquareSize: nil,
                               isRound: nil)
        navigationItem.leftBarButtonItem = dismissBtn

        self.emptyBackButtonTitleForNextView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.reset()

        _ = passwordTextField.becomeFirstResponder()
    }

    @IBAction func nextButtonClicked(_ sender: Any) {
        passwordTextField.isError = false
        passwordTextField.errorMessage = nil

        let password = passwordTextField.value
        let isPassswordValid = password.count >= 4 && password.count <= 21
        guard isPassswordValid else {
            passwordTextField.isError = true
            passwordTextField.errorMessage = LocalString._pin_code_setup1_textfield_invalid_password
            return
        }
        _ = viewModel?.setCode(passwordTextField.value)
        
        coordinator?.go(to: .step2)
    }

    @objc
    private func dismissView() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
