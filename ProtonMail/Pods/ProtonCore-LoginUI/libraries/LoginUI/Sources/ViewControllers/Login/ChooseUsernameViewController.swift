//
//  CreateAddressViewController.swift
//  ProtonCore-Login - Created on 26.11.2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_Login

protocol ChooseUsernameViewControllerDelegate: AnyObject {
    func userDidRequestGoBack()
    func userDidFinishChoosingUsername(username: String)
}

final class ChooseUsernameViewController: UIViewController, AccessibleView, ErrorCapable, Focusable {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: TitleLabel!
    @IBOutlet private weak var subtitleLabel: SubtitleLabel!
    @IBOutlet private weak var addressTextField: PMTextField!
    @IBOutlet private weak var nextButton: ProtonButton!
    @IBOutlet private weak var scrollView: UIScrollView!

    // MARK: - Properties

    weak var delegate: ChooseUsernameViewControllerDelegate?
    var viewModel: ChooseUsernameViewModel!
    var customErrorPresenter: LoginErrorPresenter?

    var focusNoMore: Bool = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()

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
        view.backgroundColor = ColorProvider.BackgroundNorm
        titleLabel.text = CoreString._ls_username_screen_title
        titleLabel.textColor = ColorProvider.TextNorm
        subtitleLabel.text = String(format: CoreString._ls_username_screen_info, viewModel.externalEmail, viewModel.appName)
        subtitleLabel.textColor = ColorProvider.TextWeak
        addressTextField.title = CoreString._ls_username_username_title
        nextButton.setTitle(CoreString._ls_username_button_title, for: .normal)

        addressTextField.suffix = "@\(viewModel.signUpDomain)"
        addressTextField.textContentType = .username
        addressTextField.autocapitalizationType = .none
        addressTextField.autocorrectionType = .no

        setUpBackArrow(action: #selector(ChooseUsernameViewController.goBack(_:)))
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
            case let .generic(message: message):
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                    self.showError(message: message)
                }
            case let .notAvailable(message: message):
                self.setError(textField: self.addressTextField, error: nil)
                if self.customErrorPresenter?.willPresentError(error: error, from: self) == true { } else {
                    self.showError(message: message)
                }
            }
        }
        viewModel.finished.bind { [weak self] username in
            self?.delegate?.userDidFinishChoosingUsername(username: username)
        }
    }

    private func setupDelegates() {
        addressTextField.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focusOnce(view: addressTextField)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationBarAdjuster.setUp(for: scrollView, parent: parent)
        scrollView.adjust(forKeyboardVisibilityNotification: nil)
    }

    // MARK: - Keyboard

    private func setupNotifications() {
        NotificationCenter.default
            .setupKeyboardNotifications(target: self, show: #selector(keyboardWillShow), hide: #selector(keyboardWillHide))
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: addressTextField, bottomView: nextButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: titleLabel, bottomView: nextButton)
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

    @objc private func goBack(_ sender: Any) {
        delegate?.userDidRequestGoBack()
    }

    private func showError(message: String) {
        showBanner(message: message, position: .top)
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
