//
//  ComposePasswordViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/24/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

protocol ComposePasswordViewControllerDelegate {
    func Cancelled()
    func Removed()
    func Apply(_ password : String, confirmPassword :String, hint : String)
}

class ComposePasswordViewController: UIViewController {
    
    @IBOutlet weak var viewTitleLable: UILabel!
    @IBOutlet weak var titleDesLabel: UILabel!
    @IBOutlet weak var moreInfoButton: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!
    @IBOutlet weak var hintField: UITextField!
    @IBOutlet weak var hintErrorLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var applyButton: UIButton!
    
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!

    fileprivate let upgradePageUrl = URL(string: "https://protonmail.com/support/knowledge-base/encrypt-for-outside-users/")!
    
    fileprivate var pwd : String = ""
    fileprivate var pwdConfirm : String  = ""
    fileprivate var pwdHint : String = ""
    
    var pwdDelegate : ComposePasswordViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTitleLable.text              = LocalString._composer_set_password
        titleDesLabel.text               = LocalString._composer_eo_desc
        moreInfoButton.setTitle(LocalString._composer_eo_info, for: .normal)
        passwordField.placeholder        = LocalString._composer_eo_msg_pwd_placeholder
        passwordErrorLabel.text          = LocalString._composer_eo_empty_pwd_desc
        confirmPasswordField.placeholder = LocalString._composer_eo_confirm_pwd_placeholder
        confirmPasswordErrorLabel.text   = LocalString._composer_eo_dismatch_pwd_desc
        hintField.placeholder            = LocalString._define_hint_optional
        cancelButton.setTitle(LocalString._general_cancel_button, for: .normal)
        removeButton.setTitle(LocalString._general_remove_button, for: .normal)
        
        applyButton.titleLabel?.numberOfLines = 1;
        applyButton.titleLabel?.adjustsFontSizeToFitWidth = true
        applyButton.titleLabel?.minimumScaleFactor = 10.0 / 16.0
        applyButton.setTitle(LocalString._general_apply_button, for: .normal)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    //
    
    @IBAction func getMoreInfoAction(_ sender: UIButton) {
        UIApplication.shared.openURL(upgradePageUrl)
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
extension ComposePasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        //self.configConstraint(false)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        //self.configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}
