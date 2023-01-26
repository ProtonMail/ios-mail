//
//  CreateAddressViewController.swift
//  ProtonCore-Login - Created on 26.11.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
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

protocol CreateAddressViewControllerDelegate: AnyObject {
    func userDidGoBack()
    func userDidFinishCreatingAddress(endLoading: @escaping () -> Void, data: LoginData)
}

final class CreateAddressViewController: UIViewController, AccessibleView, ErrorCapable, Focusable {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: TitleLabel!
    @IBOutlet private weak var subtitleLabel: SubtitleLabel!
    @IBOutlet private weak var addressTextField: PMTextField!
    @IBOutlet private weak var continueButton: ProtonButton!
    @IBOutlet private weak var cancelButton: ProtonButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet weak var domainsButton: ProtonButton!

    // MARK: - Properties

    weak var delegate: CreateAddressViewControllerDelegate?
    var viewModel: CreateAddressViewModel!
    var customErrorPresenter: LoginErrorPresenter?
    var onDohTroubleshooting: () -> Void = { }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }

    var focusNoMore = false
    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()
    var tapGesture: UITapGestureRecognizer?

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupGestures()
        setupBinding()
        setupDelegates()
        setupNotifications()
        generateAccessibilityIdentifiers()
        
        configureDomainSuffix()
    }

    private func setupUI() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        titleLabel.text = CoreString._ls_create_address_screen_title
        titleLabel.textColor = ColorProvider.TextNorm
        let attrFont = UIFont.systemFont(ofSize: 15.0, weight: .bold)
        subtitleLabel.attributedText = String(format: CoreString._ls_create_address_screen_info, viewModel.externalEmail).getAttributedString(replacement: viewModel.externalEmail, attrFont: attrFont)
        subtitleLabel.textColor = ColorProvider.TextWeak
        addressTextField.title = CoreString._ls_create_address_username_title
        continueButton.setTitle(CoreString._ls_create_address_button_title, for: .normal)
        cancelButton.setTitle(CoreString._hv_cancel_button, for: .normal)
        cancelButton.setMode(mode: .text)

        addressTextField.suffix = ""
        if let defaultUsername = viewModel.defaultUsername {
            addressTextField.value = defaultUsername
        }
        addressTextField.textContentType = .username
        addressTextField.autocapitalizationType = .none
        addressTextField.autocorrectionType = .no
        
        // domain button
        domainsButton.setMode(mode: .image(type: .textWithImage(image: nil)))

        setUpBackArrow(action: #selector(CreateAddressViewController.goBack(_:)))
    }
    
    private func setupBinding() {
        viewModel.isLoading.bind { [weak self] isLoading in
            self?.view.isUserInteractionEnabled = !isLoading
            self?.continueButton.isSelected = isLoading
        }
        viewModel.error.bind { [weak self] messageWithCode in
            guard let self = self else { return }
            switch messageWithCode.2 {
            case let .loginError(.apiMightBeBlocked(message, _)),
                let .createAddressKeysError(.apiMightBeBlocked(message, _)),
                let .createAddressError(.apiMightBeBlocked(message, _)),
                let .setUsernameError(.apiMightBeBlocked(message, _)):
                self.showError(message: message,
                               button: CoreString._net_api_might_be_blocked_button) { [weak self] in
                    self?.onDohTroubleshooting()
                }
            case let .availabilityError(.notAvailable(message: message)):
                self.setError(textField: self.addressTextField, error: nil)
                guard self.customErrorPresenter?.willPresentError(error: .notAvailable(message: message), from: self) == true else {
                    self.showError(message: message)
                    return
                }
            default:
                guard self.customErrorPresenter?.willPresentError(
                    error: CreateAddressError.generic(message: messageWithCode.0,
                                                      code: messageWithCode.1,
                                                      originalError: messageWithCode.2.originalError),
                    from: self
                ) == true else {
                    self.showError(message: messageWithCode.0)
                    return
                }
            }
        }
        viewModel.finished.bind { [weak self] data in
            self?.delegate?.userDidFinishCreatingAddress(endLoading: { [weak self] in self?.viewModel.isLoading.value = false }, data: data)
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
        adjust(scrollView, notification: notification, topView: addressTextField, bottomView: continueButton)
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        adjust(scrollView, notification: notification, topView: titleLabel, bottomView: continueButton)
    }

    // MARK: - Actions

    private func setupGestures() {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        tapGesture?.delaysTouchesBegan = false
        tapGesture?.delaysTouchesEnded = false
        guard let tapGesture = tapGesture else { return }
        self.view.addGestureRecognizer(tapGesture)
    }

    @IBAction private func continuePressed(_ sender: Any) {
        guard setAddressTextFieldError() else {
            return
        }

        PMBanner.dismissAll(on: self)
        _ = addressTextField.resignFirstResponder()
        viewModel.finish(username: addressTextField.value)
    }
    
    @IBAction private func cancelPressed(_ sender: Any) {
        viewModel.logout()
        delegate?.userDidGoBack()
    }
    
    @objc private func goBack(_ sender: Any) {
        viewModel.logout()
        delegate?.userDidGoBack()
    }

    private func showError(message: String, button: String? = nil, action: (() -> Void)? = nil) {
        showBanner(message: message, position: .top)
    }

    // MARK: - Validation

    @discardableResult
    private func setAddressTextFieldError() -> Bool {
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
    
    private func configureDomainSuffix() {
        domainsButton.setTitle("@\(viewModel.currentlyChosenSignUpDomain)", for: .normal)
        if viewModel.allSignUpDomains.count > 1 {
            domainsButton.isUserInteractionEnabled = true
            domainsButton.setMode(mode: .image(type: .textWithChevron))
        } else {
            domainsButton.isUserInteractionEnabled = false
            domainsButton.setMode(mode: .image(type: .textWithImage(image: nil)))
        }
    }
    
    @IBAction private func onDomainsButtonTapped() {
        dismissKeyboard()
        var sheet: PMActionSheet?
        let currentDomain = viewModel.currentlyChosenSignUpDomain
        let items = viewModel.allSignUpDomains.map { [weak self] domain in
            PMActionSheetPlainItem(title: "@\(domain)", icon: nil, isOn: domain == currentDomain) { [weak self] _ in
                sheet?.dismiss(animated: true)
                self?.viewModel.currentlyChosenSignUpDomain = domain
                self?.configureDomainSuffix()
            }
        }
        let header = PMActionSheetHeaderView(title: CoreString._su_domains_sheet_title,
                                             subtitle: nil,
                                             leftItem: PMActionSheetPlainItem(title: nil, icon: IconProvider.crossSmall) { _ in sheet?.dismiss(animated: true) },
                                             rightItem: nil,
                                             hasSeparator: false)
        let itemGroup = PMActionSheetItemGroup(items: items, style: .clickable)
        sheet = PMActionSheet(headerView: header, itemGroups: [itemGroup], showDragBar: false)
        sheet?.eventsListener = self
        sheet?.presentAt(self, animated: true)
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        if addressTextField.isFirstResponder {
            _ = addressTextField.resignFirstResponder()
        }
    }
}

// MARK: - Text field delegate

extension CreateAddressViewController: PMTextFieldDelegate {

    func didChangeValue(_ textField: PMTextField, value: String) {}

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        _ = textField.resignFirstResponder()
        return true
    }

    func didBeginEditing(textField: PMTextField) {}

    func didEndEditing(textField: PMTextField) {
        setAddressTextFieldError()
    }
}

extension CreateAddressViewController: PMActionSheetEventsListener {
    func willPresent() {
        tapGesture?.cancelsTouchesInView = false
        domainsButton?.isSelected = true
    }

    func willDismiss() {
        tapGesture?.cancelsTouchesInView = true
        domainsButton?.isSelected = false
    }
    
    func didDismiss() { }
}
