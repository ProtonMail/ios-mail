//
//  ComposePasswordVC.swift
//  ProtonMail -
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

import ProtonCore_UIFoundations
import UIKit

protocol ComposePasswordDelegate: AnyObject {
    func apply(password: String, confirmPassword: String, hint: String)
    func removedPassword()
}

final class ComposePasswordVC: UIViewController, AccessibleView {

    @IBOutlet private var contentView: UIView!
    @IBOutlet private var infoIcon: UIImageView!
    @IBOutlet private var infoText: UITextView!
    @IBOutlet private var passwordText: PMTextField!
    @IBOutlet private var confirmText: PMTextField!
    @IBOutlet private var passwordHintLabel: UILabel!
    @IBOutlet private var passwordHintView: UIView!
    @IBOutlet private var passwordHintPlaceholder: UILabel!
    @IBOutlet private var passwordHintText: UITextView!
    @IBOutlet private var applyButton: ProtonButton!
    @IBOutlet private var removeView: UIView!
    @IBOutlet private var removeIcon: UIImageView!
    @IBOutlet private var removeLabel: UILabel!
    @IBOutlet private weak var scrollView: UIScrollView!

    private weak var delegate: ComposePasswordDelegate?
    private var encryptionPassword: String = ""
    private var encryptionConfirmPassword: String = ""
    private var encryptionPasswordHint: String = ""

    static func instance(password: String,
                         confirmPassword: String,
                         hint: String,
                         delegate: ComposePasswordDelegate?) -> ComposePasswordVC {
        let passwordVC = Self(nibName: nil, bundle: nil)
        passwordVC.encryptionPassword = password
        passwordVC.encryptionConfirmPassword = confirmPassword
        passwordVC.encryptionPasswordHint = hint
        passwordVC.delegate = delegate
        if #available(iOS 13.0, *) {
            passwordVC.isModalInPresentation = true
        }
        return passwordVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addKeyboardObserver(self)
        self.setup()
        generateAccessibilityIdentifiers()
        initializeHideKeyboard()
    }

    @IBAction private func clickApplyButton(_ sender: Any) {
        guard self.isGoodPassword() else {
            return
        }

        guard self.checkConfirmPassword() else {
            return
        }
        self.delegate?.apply(password: self.passwordText.value,
                             confirmPassword: self.confirmText.value,
                             hint: self.passwordHintText.text)
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    private func clickRemove() {
        self.delegate?.removedPassword()
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    private func clickBackButton() {
        guard self.encryptionPassword == self.passwordText.value &&
                self.encryptionConfirmPassword == self.confirmText.value &&
                self.encryptionPasswordHint == self.passwordHintText.text else {
            self.showDiscardAlert()
            return
        }
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: UI setup
extension ComposePasswordVC {
    private func setup() {
        view.backgroundColor = ColorProvider.BackgroundNorm
        contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.setupNavigation()
        self.setupInfoView()
        self.setupPasswordView()
        self.setupPasswordHintView()
        self.setupApplyButton()
        self.setupRemoveView()
        self.setupVoiceOver()
    }

    private func setupNavigation() {
        self.title = LocalString._composer_set_password

        let backButtonItem = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(self.clickBackButton))
        self.navigationItem.leftBarButtonItem = backButtonItem
    }

    private func setupInfoView() {
        guard let url = URL(string: Link.encryptOutsideInfo) else {
            return
        }
        self.infoIcon.tintColor = ColorProvider.IconWeak
        let descStr = LocalString._composer_eo_desc.apply(style: .DefaultSmallWeek)
        var moreAttr = FontManager.DefaultSmallWeak
        moreAttr[.link] = url
        let moreStr = " \(LocalString._learn_more)".apply(style: moreAttr)
        let attrStr = NSMutableAttributedString(attributedString: descStr)
        attrStr.append(moreStr)
        self.infoText.textContainerInset = .zero
        self.infoText.attributedText = attrStr
        self.infoText.linkTextAttributes = [.foregroundColor: ColorProvider.InteractionNorm ]
        self.infoText.backgroundColor = ColorProvider.BackgroundNorm
    }

    private func setupPasswordView() {
        self.passwordText.title = LocalString._composer_eo_msg_pwd_placeholder
        self.passwordText.placeholder = LocalString._composer_eo_msg_pwd_hint
        self.passwordText.value = self.encryptionPassword
        self.passwordText.delegate = self
        self.passwordText.backgroundColor = ColorProvider.BackgroundNorm

        self.confirmText.title = LocalString._composer_eo_repeat_pwd
        self.confirmText.placeholder = LocalString._composer_eo_repeat_pwd_placeholder
        self.confirmText.value = self.encryptionConfirmPassword
        self.confirmText.delegate = self
        self.confirmText.backgroundColor = ColorProvider.BackgroundNorm
    }

    private func setupPasswordHintView() {
        self.passwordHintLabel.attributedText = LocalString._composer_password_hint_title.apply(style: .CaptionStrong)
        self.passwordHintView.backgroundColor = ColorProvider.BackgroundSecondary
        self.passwordHintText.contentInset = .zero
        self.passwordHintText.delegate = self
        self.passwordHintText.text = self.encryptionPasswordHint
        self.passwordHintPlaceholder.attributedText = LocalString._define_hint_optional.apply(style: .DefaultHint)
        self.passwordHintPlaceholder.isHidden = !self.encryptionPasswordHint.isEmpty
        self.passwordHintView.accessibilityIdentifier = "ComposePasswordVC.passwordHintView"
        self.passwordHintView.roundCorner(8)
    }

    private func setupApplyButton() {
        self.applyButton.setMode(mode: .solid)
        let title = self.encryptionPassword.isEmpty ? LocalString._composer_password_apply: LocalString._save_changes
        self.applyButton.setTitle(title, for: .normal)
        self.checkApplyButtonStatus()
        self.applyButton.accessibilityIdentifier = "ComposePasswordVC.applyButton"
    }

    private func setupRemoveView() {
        guard !self.encryptionPassword.isEmpty else {
            self.removeView.isHidden = true
            return
        }
        self.removeView.isHidden = false
        self.removeView.backgroundColor = ColorProvider.BackgroundSecondary
        self.removeIcon.tintColor = ColorProvider.IconNorm
        self.removeLabel.attributedText = LocalString._composer_eo_remove_pwd.apply(style: FontManager.Caption)

        let tap = UITapGestureRecognizer(target: self, action: #selector(self.clickRemove))
        self.removeView.addGestureRecognizer(tap)
    }

    private func showDiscardAlert() {
        let title = LocalString._warning
        let message = LocalString._discard_warning
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let discardBtn = UIAlertAction(title: LocalString._general_discard, style: .destructive) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        let cancelBtn = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [discardBtn, cancelBtn].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }

    private func setupVoiceOver() {
        view.accessibilityElements = [infoText as Any,
                                      passwordText as Any,
                                      confirmText as Any,
                                      passwordHintLabel as Any,
                                      passwordHintText as Any,
                                      applyButton as Any]
        let dismissKeyboardAction = UIAccessibilityCustomAction(name: LocalString._composer_voiceover_dismiss_keyboard,
                                                                target: self,
                                                                selector: #selector(dismissMyKeyboard))
        passwordHintText.accessibilityCustomActions = [dismissKeyboardAction]
    }
}

extension ComposePasswordVC {
    private func isGoodPassword() -> Bool {
        let count = self.passwordText.value.count
        if count >= 8 && count <= 21 {
            self.passwordText.errorMessage = ""
            return true
        }
        self.passwordText.errorMessage = LocalString._composer_eo_msg_pwd_length_error
        return false
    }

    private func checkConfirmPassword() -> Bool {
        let isOK = self.confirmText.value == self.passwordText.value
        self.confirmText.errorMessage = isOK ? "": LocalString._composer_eo_repeat_pwd_match_error
        return isOK
    }

    private func checkApplyButtonStatus() {
        let hasPassword = !self.passwordText.value.isEmpty
        let hasConfirm = !self.confirmText.value.isEmpty
        self.applyButton.isEnabled = hasPassword && hasConfirm
    }
}

extension ComposePasswordVC: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        if let scrollView = self.scrollView,
           let userInfo = notification.userInfo,
           let endValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey],
           let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey],
           let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {

            let endRect = view.convert((endValue as AnyObject).cgRectValue, from: view.window)
            let keyboardOverlap = max((findEditingView()?.frame.maxY ?? 0.0) - endRect.origin.y, 0)

            scrollView.contentInset.bottom = endRect.height
            scrollView.scrollIndicatorInsets.bottom = endRect.height
            if keyboardOverlap > 0 {
                scrollView.setContentOffset(CGPoint(x: 0, y: keyboardOverlap), animated: true)
            }

            let duration = (durationValue as AnyObject).doubleValue
            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
            UIView.animate(withDuration: duration ?? 0.0,
                           delay: 0,
                           options: options,
                           animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func findEditingView() -> UIView? {
        if passwordText.isFirstResponder {
            return passwordText
        } else if confirmText.isFirstResponder {
            return confirmText
        } else if passwordHintText.isFirstResponder {
            // return the parent view of hint view
            return passwordHintView
        } else {
            return nil
        }
    }

    private func initializeHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissMyKeyboard))

        view.addGestureRecognizer(tap)
    }

    @objc
    private func dismissMyKeyboard() {
        view.endEditing(true)
    }
}

extension ComposePasswordVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if var value = textView.text,
           let textRange = Range(range, in: value) {
            value.replaceSubrange(textRange, with: text)
            self.passwordHintPlaceholder.isHidden = !value.isEmpty
            textView.attributedText = value.apply(style: .Default)
        }

        return false
    }
}

extension ComposePasswordVC: PMTextFieldDelegate {
    func didChangeValue(_ textField: PMTextField, value: String) {
        self.checkApplyButtonStatus()
    }

    func didEndEditing(textField: PMTextField) {
        if textField == self.passwordText {
            _ = self.isGoodPassword()
        } else if textField == self.confirmText {
            _ = self.checkConfirmPassword()
        }
    }

    func textFieldShouldReturn(_ textField: PMTextField) -> Bool {
        if textField == self.passwordText {
            _ = self.confirmText.becomeFirstResponder()
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: self.confirmText)
            }
        } else if textField == self.confirmText {
            self.passwordHintText.becomeFirstResponder()
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .screenChanged, argument: self.passwordHintText)
            }
        }
        return true
    }

    func didBeginEditing(textField: PMTextField) {

    }
}
