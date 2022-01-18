//
//  ChangePasswordViewController.swift
//  ProtonMail - Created on 3/17/15.
//
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

import MBProgressHUD
import ProtonCore_Networking
import ProtonCore_UIFoundations
import UIKit
import class ProtonCore_Services.APIErrorCode

class ChangePasswordViewController: UIViewController {

    @IBOutlet private weak var currentPasswordEditor: PMTextField!
    @IBOutlet private weak var newPasswordEditor: PMTextField!
    @IBOutlet private weak var confirmPasswordEditor: PMTextField!
    @IBOutlet private weak var saveButton: ProtonButton!
    @IBOutlet private weak var topOffset: NSLayoutConstraint!

    var keyboardHeight: CGFloat = 0.0
    var textFieldPoint: CGFloat = 0.0

    let kAsk2FASegue = "password_to_twofa_code_segue"

    private var doneButton: UIBarButtonItem!
    private var viewModel: ChangePasswordViewModel!

    func setViewModel(_ viewModel: ChangePasswordViewModel) {
        self.viewModel = viewModel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm

        saveButton.setMode(mode: .solid)
        saveButton.setTitle(LocalString._general_save_action, for: .normal)
        saveButton.isEnabled = false

        self.navigationItem.title = viewModel.getNavigationTitle()

        self.currentPasswordEditor.title = viewModel.getCurrentPasswordEditorTitle()
        self.currentPasswordEditor.isPassword = true
        self.currentPasswordEditor.delegate = self

        self.newPasswordEditor.title = viewModel.getNewPasswordEditorTitle()
        self.newPasswordEditor.isPassword = true
        self.newPasswordEditor.delegate = self

        self.confirmPasswordEditor.title = viewModel.getConfirmPasswordEditorTitle()
        self.confirmPasswordEditor.isPassword = true
        self.confirmPasswordEditor.delegate = self

        currentPasswordEditor.placeholder = LocalString._settings_current_password
        newPasswordEditor.placeholder = LocalString._settings_new_password
        confirmPasswordEditor.placeholder = LocalString._settings_confirm_new_password

        focusFirstEmpty()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kAsk2FASegue, let next = segue.destination as? TwoFACodeViewController {
            next.delegate = self
            next.mode = .twoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: next)
        }
    }

    func setPresentationStyleForSelfController(_ selfController: UIViewController,
                                               presentingController: UIViewController) {
        presentingController.providesPresentationContextTransitionStyle = true
        presentingController.definesPresentationContext = true
        presentingController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
    }

    // MARK: - private methods
    private func dismissKeyboard() {
        if self.currentPasswordEditor != nil {
            _ = self.currentPasswordEditor.resignFirstResponder()
        }
        if self.newPasswordEditor != nil {
            _ = self.newPasswordEditor.resignFirstResponder()
        }
        if self.confirmPasswordEditor != nil {
            _ = self.confirmPasswordEditor.resignFirstResponder()
        }
    }

    private func updateView() {
        let screenHeight = view.frame.height
        let keyboardTop = screenHeight - self.keyboardHeight
        if self.textFieldPoint > keyboardTop {
            topOffset.constant = keyboardTop - self.textFieldPoint
        } else {
            topOffset.constant = 32
        }
    }

    private func isInputEmpty() -> Bool {
        let currentPassword = (currentPasswordEditor.value ) // .trim()
        let newPassword = (newPasswordEditor.value ) // .trim()
        let confirmNewPassword = (confirmPasswordEditor.value ) // .trim()
        if !currentPassword.isEmpty {
            return false
        }
        if !newPassword.isEmpty {
            return false
        }
        if !confirmNewPassword.isEmpty {
            return false
        }
        return true
    }

    private func focusFirstEmpty() {
        let currentPassword = (currentPasswordEditor.value ) // .trim()
        let newPassword = (newPasswordEditor.value ) // .trim()
        let confirmNewPassword = (confirmPasswordEditor.value ) // .trim()
        if currentPassword.isEmpty {
            _ = currentPasswordEditor.becomeFirstResponder()
        } else if newPassword.isEmpty {
            _ = newPasswordEditor.becomeFirstResponder()
        } else if confirmNewPassword.isEmpty {
            _ = confirmPasswordEditor.becomeFirstResponder()
        }
    }

    var cached2faCode: String?

    private func startUpdatePwd () {
        dismissKeyboard()
        if viewModel.needAsk2FA() && cached2faCode == nil {
            NotificationCenter.default.removeKeyboardObserver(self)
            self.performSegue(withIdentifier: self.kAsk2FASegue, sender: self)
        } else {
            MBProgressHUD.showAdded(to: view, animated: true)
            viewModel.setNewPassword(currentPasswordEditor.value ,
                                     newPassword: newPasswordEditor.value ,
                                     confirmNewPassword: confirmPasswordEditor.value ,
                                     tFACode: self.cached2faCode,
                                     complete: { _, error in
                self.cached2faCode = nil
                MBProgressHUD.hide(for: self.view, animated: true)
                if let error = error, !error.isBadVersionError {
                    if error.code == APIErrorCode.UserErrorCode.currentWrong {
                        _ = self.currentPasswordEditor.becomeFirstResponder()
                    } else if error.code == APIErrorCode.UserErrorCode.newNotMatch {
                        _ = self.newPasswordEditor.becomeFirstResponder()
                    }
                    if let responseError = error as? ResponseError,
                       let underlyingError = responseError.underlyingError {
                        underlyingError.alertToast()
                    } else {
                        error.alertToast()
                    }
                } else {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
            })
        }
    }

    // MARK: - Actions
    @IBAction func saveAction(_ sender: Any) {
        startUpdatePwd()
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ChangePasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        keyboardHeight = 0
        updateView()
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let info = notification.userInfo as NSDictionary?
        if let keyboardSize = (info?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            updateView()
        }
    }
}

extension ChangePasswordViewController: TwoFACodeViewControllerDelegate {
    func confirmedCode(_ code: String, pwd: String) {
        NotificationCenter.default.addKeyboardObserver(self)
        self.cached2faCode = code
        self.startUpdatePwd()
    }

    func cancel2FA() {
        NotificationCenter.default.addKeyboardObserver(self)
    }
}

extension ChangePasswordViewController: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
    }

    func didEndEditing(textField: PMTextField) {
        if isInputEmpty() {
            self.saveButton.isEnabled = false
        } else {
            self.saveButton.isEnabled = true
        }
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        switch textField {
        case currentPasswordEditor:
            _ = newPasswordEditor.becomeFirstResponder()
        case newPasswordEditor:
            _ = confirmPasswordEditor.becomeFirstResponder()
        default:
            if !isInputEmpty() {
                startUpdatePwd()
            } else {
                focusFirstEmpty()
            }
        }
        return true
    }

    func didBeginEditing(textField: PMTextField) {
        textFieldPoint = textField.frame.origin.y + textField.frame.height

        if textField == confirmPasswordEditor {
            let padding: CGFloat = 24
            textFieldPoint += ( padding + self.saveButton.frame.height )
        }
        updateView()
    }
}
