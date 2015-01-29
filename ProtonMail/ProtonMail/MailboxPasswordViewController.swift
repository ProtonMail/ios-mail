//
//  MailboxPasswordViewController.swift
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

import Foundation

class MailboxPasswordViewController: UIViewController {
    let animationDuration: NSTimeInterval = 0.5
    let buttonDisabledAlpha: CGFloat = 0.5
    let keyboardPadding: CGFloat = 12

    @IBOutlet weak var decryptButton: UIButton!
    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rememberButton: UIButton!
    
    var isRemembered: Bool = sharedUserDataService.isRememberMailboxPassword
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDecryptButton()
        rememberButton.selected = isRemembered
        passwordTextField.roundCorners()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        navigationController?.setNavigationBarHidden(true, animated: true)
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    func setupDecryptButton() {
        decryptButton.alpha = buttonDisabledAlpha
        decryptButton.roundCorners()
    }
    
    // MARK: - private methods
    
    func decryptPassword() {
        sharedUserDataService.setMailboxPassword(passwordTextField.text, isRemembered: isRemembered)
        (UIApplication.sharedApplication().delegate as AppDelegate).switchTo(storyboard: .inbox)
    }
    
    func updateButton(button: UIButton) {
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            button.alpha = button.enabled ? 1.0 : self.buttonDisabledAlpha
        })
    }
    
    // MARK: - Actions
    
    @IBAction func decryptAction(sender: UIButton) {
        decryptPassword()
    }
    
    @IBAction func rememberButtonAction(sender: UIButton) {
        isRemembered = !isRemembered
        rememberButton.selected = isRemembered
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        passwordTextField.resignFirstResponder()
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension MailboxPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
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
extension MailboxPasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        decryptButton.enabled = false
        updateButton(decryptButton)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == passwordTextField {
            decryptButton.enabled = !changedText.isEmpty
        }
        
        updateButton(decryptButton)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if !passwordTextField.text.isEmpty {
            decryptPassword()
        }
        
        return true
    }
}
