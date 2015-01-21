//
//  SignInViewController.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

class SignInViewController: UIViewController {
    let animationDuration: NSTimeInterval = 0.5
    let keyboardPadding: CGFloat = 12
    let signInButtonDisabledAlpha: CGFloat = 0.5
    let signUpURL = NSURL(string: "https://protonmail.ch/sign_up.php")!
    
    var isRemembered = false
        
    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rememberMeSwitch.setOn(isRemembered, animated: false)
        setupSignInButton()
        setupSignUpButton()
        signInIfRememberedCredentials()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    // MARK: - Private methods
    
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func setupSignInButton() {
        signInButton.layer.cornerRadius = 4.0
        signInButton.clipsToBounds = true
        signInButton.alpha = signInButtonDisabledAlpha
    }
    
    // FIXME: Work around for http://stackoverflow.com/questions/25925914/attributed-string-with-custom-fonts-in-storyboard-does-not-load-correctly <http://openradar.appspot.com/18425809>
    func setupSignUpButton() {
        let needAnAccount = NSLocalizedString("Need an account? ", comment: "Need an account? ")
        let signUp = NSLocalizedString("SignUp.", comment: "SignUp.")
        
        let title = NSMutableAttributedString(string: needAnAccount, attributes: [NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleNone.rawValue])
        let signUpAttributed = NSAttributedString(string: signUp, attributes: [NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue])
        
        title.appendAttributedString(signUpAttributed)
        
        if let font = UIFont(name: "Roboto-Thin", size: 12.5) {
            title.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, title.length))
        }
        
        signUpButton.setAttributedTitle(title, forState: .Normal)
    }
    
    func signIn() {
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        
        AuthenticationService().signIn(usernameTextField.text, password: passwordTextField.text, isRemembered: isRemembered) {error in
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
                
                let alertController = error.alertController()
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK"), style: .Default, handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func signInIfRememberedCredentials() {
        if let (username, password) = AuthenticationService().rememberedCredentials() {
            isRemembered = true
            rememberMeSwitch.setOn(true, animated: false)
            usernameTextField.text = username
            passwordTextField.text = password
            
            signIn()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func rememberMeChanged(sender: UISwitch) {
        isRemembered = sender.on
    }
    
    @IBAction func signInAction(sender: UIButton) {
        dismissKeyboard()
        signIn()
    }
    
    @IBAction func signUpAction(sender: UIButton) {
        dismissKeyboard()
        UIApplication.sharedApplication().openURL(signUpURL)
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignInViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        
        keyboardPaddingConstraint.constant = 0
        
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        
        keyboardPaddingConstraint.constant = keyboardInfo.beginFrame.height + keyboardPadding
        
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension SignInViewController: UITextFieldDelegate {
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == usernameTextField {
            signInButton.enabled = !changedText.isEmpty && !passwordTextField.text.isEmpty
        } else if textField == passwordTextField {
            signInButton.enabled = !changedText.isEmpty && !usernameTextField.text.isEmpty
        }
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.signInButton.alpha = self.signInButton.enabled ? 1.0 : self.signInButtonDisabledAlpha
        })
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        if !usernameTextField.text.isEmpty && !passwordTextField.text.isEmpty {
            signIn()
        }
        
        return true
    }
}