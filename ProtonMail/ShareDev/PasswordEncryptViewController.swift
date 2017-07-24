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
        
        viewTitleLable.text              = NSLocalizedString("Set Password", comment: "Title")
        titleDesLabel.text               = NSLocalizedString("Set a password to encrypt this message for non-ProtonMail users.", comment: "Description")
        passwordField.placeholder        = NSLocalizedString("Message Password", comment: "Placeholder")
        passwordErrorLabel.text          = NSLocalizedString("The message password can't be empty", comment: "Description")
        confirmPasswordField.placeholder = NSLocalizedString("Confirm Password", comment: "Placeholder")
        confirmPasswordErrorLabel.text   = NSLocalizedString("The message password didn't match", comment: "Description")
        hintField.placeholder            = NSLocalizedString("Define Hint (Optional)", comment: "Placeholder")
        
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "Action"),
                              for: .normal)
        removeButton.setTitle(NSLocalizedString("Remove", comment: "Action"),
                              for: .normal)
        applyButton.setTitle(NSLocalizedString("Apply", comment: "Action"),
                             for: .normal)
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
        
        let pwd = (passwordField.text ?? "").trim()
        let pwdConfirm = (confirmPasswordField.text ?? "").trim()
        let hint = (hintField.text ?? "").trim()
        
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
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
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
//        let keyboardInfo = notification.keyboardInfo
//        scrollBottomPaddingConstraint.constant = 0.0
//        //self.configConstraint(false)
//        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//        }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
//        let keyboardInfo = notification.keyboardInfo
//        let info: NSDictionary = notification.userInfo! as NSDictionary
//        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
//            scrollBottomPaddingConstraint.constant = keyboardSize.height;
//        }
//        //self.configConstraint(true)
//        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//        }, completion: nil)
    }
}
