//
//  TwoFACodeViewController.swift
//  Proton Mail - Created on 11/3/16.
//
//
//  Copyright (c) 2019 Proton AG
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

import ProtonCore_Foundations

protocol TwoFACodeViewControllerDelegate {
    func cancel2FA()
    func confirmedCode(_ code: String, pwd: String)
}

class TwoFACodeViewController: UIViewController, AccessibleView {
    @IBOutlet weak var twoFACodeView: TwoFACodeView!
    var delegate: TwoFACodeViewControllerDelegate?

    var mode: AuthMode!

    @IBOutlet weak var tfaCodeCenterConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.twoFACodeView.delegate = self
        self.twoFACodeView.layer.cornerRadius = 8
        self.twoFACodeView.initViewMode(mode)
        self.twoFACodeView.showKeyboard()
        generateAccessibilityIdentifiers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
        self.twoFACodeView.showKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension TwoFACodeViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        tfaCodeCenterConstraint.constant = 0.0
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        guard let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {return}
        let keyboardInfo = notification.keyboardInfo
        tfaCodeCenterConstraint.constant = (keyboardSize.height / 2) * -1.0
        UIView.animate(withDuration: keyboardInfo.duration) {
            self.view.layoutIfNeeded()
        }
    }
}

extension TwoFACodeViewController: TwoFACodeViewDelegate {

    func ConfirmedCode(_ code: String, pwd: String) {
        delegate?.confirmedCode(code, pwd: pwd)
        self.dismiss(animated: true, completion: nil)
    }

    func Cancel() {
        delegate?.cancel2FA()
        self.dismiss(animated: true, completion: nil)
    }
}
