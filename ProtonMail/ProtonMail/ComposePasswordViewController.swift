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
    func Apply(password : String, confirmPassword :String, hint : String)
}

class ComposePasswordViewController: UIViewController {

    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!
    
    @IBOutlet weak var hintField: UITextField!
    @IBOutlet weak var hintErrorLabel: UILabel!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!

    @IBOutlet weak var removeButton: UIButton!
    private let upgradePageUrl = NSURL(string: "https://protonmail.com/support/knowledge-base/encrypt-for-outside-users/")!
    
    private var pwd : String = ""
    private var pwdConfirm : String  = ""
    private var pwdHint : String = ""
    
    var pwdDelegate : ComposePasswordViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        
        self.passwordField.text = pwd
        self.confirmPasswordField.text = pwdConfirm
        self.hintField.text = pwdHint
        
        if (!pwd.isEmpty) {
            removeButton.hidden = false
        } else {
            removeButton.hidden = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    //
    
    @IBAction func getMoreInfoAction(sender: UIButton) {
        UIApplication.sharedApplication().openURL(upgradePageUrl)
    }

    @IBAction func closeAction(sender: AnyObject) {
        pwdDelegate?.Cancelled()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func removeAction(sender: UIButton) {
        pwdDelegate?.Removed()
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func applyAction(sender: UIButton) {
        passwordErrorLabel.hidden = true
        confirmPasswordErrorLabel.hidden = true
        
        let pwd = passwordField.text ?? ""
        let pwdConfirm = confirmPasswordField.text ?? ""
        let hint = hintField.text ?? ""
        
        if pwd.isEmpty {
            passwordErrorLabel.hidden = false
            passwordErrorLabel.shake(3, offset: 10)
            return
        }
        
        if pwd != pwdConfirm {
            confirmPasswordErrorLabel.hidden = false
            confirmPasswordErrorLabel.shake(3, offset: 10)
            return
        }
        
        pwdDelegate?.Apply(pwd, confirmPassword: pwdConfirm, hint: hint)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    internal func dismissKeyboard() {
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
        hintField.resignFirstResponder()
    }
    
    func setupPasswords(password : String, confirmPassword : String, hint : String) {
        self.pwd = password
        self.pwdConfirm = confirmPassword
        self.pwdHint = hint
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ComposePasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        //self.configConstraint(false)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        //self.configConstraint(true)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}