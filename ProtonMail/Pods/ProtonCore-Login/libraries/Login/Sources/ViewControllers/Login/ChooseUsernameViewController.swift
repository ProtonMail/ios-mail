//
//  CreateAddressViewController.swift
//  PMLogin - Created on 26.11.2020.
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
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol ChooseUsernameViewControllerDelegate: AnyObject {
    func userDidRequestGoBack()
    func userDidFinishChoosingUsername(username: String)
}

final class ChooseUsernameViewController: UIViewController, AccessibleView, ErrorCapable {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: TitleLabel!
    @IBOutlet private weak var subtitleLabel: SubtitleLabel!
    @IBOutlet private weak var addressTextField: PMTextField!
    @IBOutlet private weak var nextButton: ProtonButton!
    @IBOutlet private weak var scrollView: UIScrollView!

    // MARK: - Properties

    weak var delegate: ChooseUsernameViewControllerDelegate?
    var viewModel: ChooseUsernameViewModel!

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupDelegates()
        setupNotifications()
        generateAccessibilityIdentifiers()
    }

    private func setupUI() {
        view.backgroundColor = UIColorManager.BackgroundNorm
        titleLabel.text = CoreString._ls_username_screen_title
        subtitleLabel.text = String(format: CoreString._ls_username_screen_info, viewModel.externalEmail, viewModel.appName)
        addressTextField.title = CoreString._ls_username_username_title
        nextButton.setTitle(CoreString._ls_username_button_title, for: .normal)

        addressTextField.suffix = "@\(viewModel.signUpDomain)"
        addressTextField.textContentType = .username
        addressTextField.autocapitalizationType = .none
        addressTextField.autocorrectionType = .no
    }

    private func setupBinding() {
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.nextButton.isSelected = isLoading
        }
        viewModel.error.bind { [weak self] error in
            guard let self = self else {
                return
            }

            switch error {
            case let  .generic(message: message):
                self.showError(message: message)
            case let .notAvailable(message: message):
                self.setError(textField: self.addressTextField, error: nil)
                self.showError(message: message)
            }
        }
        viewModel.finished.bind { [weak self] username in
            self?.delegate?.userDidFinishChoosingUsername(username: username)
        }
    }

    private func setupDelegates() {
        addressTextField.delegate = self
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Keyboard

    @objc private func adjustKeyboard(notification: NSNotification) {
        scrollView.adjustForKeyboard(notification: notification)
    }

    // MARK: - Actions

    @IBAction private func nextPressed(_ sender: Any) {
        guard validateUsername() else {
            return
        }

        PMBanner.dismissAll(on: self)
        clearError(textField: addressTextField)
        _ = addressTextField.resignFirstResponder()
        viewModel.checkAvailability(username: addressTextField.value)
    }

    @IBAction private func goBack(_ sender: Any) {
        delegate?.userDidRequestGoBack()
    }

    private func showError(message: String) {
        showBanner(message: message, position: PMBannerPosition.topCustom(UIEdgeInsets(top: 64, left: 16, bottom: CGFloat.infinity, right: 16)))
    }

    // MARK: - Validation

    @discardableResult
    private func validateUsername() -> Bool {
        let usernameValid = viewModel.validate(username: addressTextField.value)
        switch usernameValid {
        case let .failure(error):
            setError(textField: addressTextField, error: error)
            return false
        case .success:
            clearError(textField: addressTextField)
            return true
        }
    }
}

// MARK: - Text field delegate

extension ChooseUsernameViewController: PMTextFieldDelegate {

    func didChangeValue(_ textField: PMTextField, value: String) {}

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        _ = textField.resignFirstResponder()
        return true
    }

    func didBeginEditing(textField: PMTextField) {}

    func didEndEditing(textField: PMTextField) {
        validateUsername()
    }
}
