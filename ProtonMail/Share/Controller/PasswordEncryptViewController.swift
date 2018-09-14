//
//  PasswordEncryptViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/24/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UIKit

protocol PasswordEncryptViewControllerDelegate {
    func Cancelled()
    func Removed()
    func Apply(_ password : String, confirmPassword :String, hint : String)
}

class PasswordEncryptViewController: UIViewController {
    
    @IBOutlet weak var viewTitleLable: UILabel!
    @IBOutlet weak var titleDesLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!
    @IBOutlet weak var hintField: UITextField!
    @IBOutlet weak var hintErrorLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var applyButton: UIButton!
    //
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    fileprivate var pwd : String = ""
    fileprivate var pwdConfirm : String  = ""
    fileprivate var pwdHint : String = ""
    
    var pwdDelegate : PasswordEncryptViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTitleLable.text              = LocalString._composer_set_password
        titleDesLabel.text               = LocalString._composer_eo_desc
        passwordField.placeholder        = LocalString._composer_eo_msg_pwd_placeholder
        passwordErrorLabel.text          = LocalString._composer_eo_empty_pwd_desc
        confirmPasswordField.placeholder = LocalString._composer_eo_confirm_pwd_placeholder
        confirmPasswordErrorLabel.text   = LocalString._composer_eo_dismatch_pwd_desc
        hintField.placeholder            = LocalString._define_hint_optional
        
        cancelButton.setTitle(LocalString._general_cancel_button, for: .normal)
        removeButton.setTitle(LocalString._general_remove_button, for: .normal)
        applyButton.setTitle(LocalString._general_apply_button, for: .normal)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
        
        self.passwordField.text = pwd
        self.confirmPasswordField.text = pwdConfirm
        self.hintField.text = pwdHint
        
        if (!pwd.isEmpty) {
            removeButton.isHidden = false
        } else {
            removeButton.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        pwdDelegate?.Cancelled()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func removeAction(_ sender: UIButton) {
        pwdDelegate?.Removed()
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func applyAction(_ sender: UIButton) {
        passwordErrorLabel.isHidden = true
        confirmPasswordErrorLabel.isHidden = true
        
        let pwd = (passwordField.text ?? "")
        let pwdConfirm = (confirmPasswordField.text ?? "")
        let hint = (hintField.text ?? "")
        
        if pwd.isEmpty {
            passwordErrorLabel.isHidden = false
            passwordErrorLabel.shake(3, offset: 10)
            return
        }
        
        if pwd != pwdConfirm {
            confirmPasswordErrorLabel.isHidden = false
            confirmPasswordErrorLabel.shake(3, offset: 10)
            return
        }
        
        pwdDelegate?.Apply(pwd, confirmPassword: pwdConfirm, hint: hint)
        self.dismiss(animated: true, completion: nil)
    }

    internal func dismissKeyboard() {
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
        hintField.resignFirstResponder()
    }
    
    func setupPasswords(_ password : String, confirmPassword : String, hint : String) {
        self.pwd = password
        self.pwdConfirm = confirmPassword
        self.pwdHint = hint
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension PasswordEncryptViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        scrollBottomPaddingConstraint.constant = 0.0
        guard let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) else {
                return
        }
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        guard let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) else {
                return
        }
        scrollBottomPaddingConstraint.constant = keyboardSize.height;
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}
