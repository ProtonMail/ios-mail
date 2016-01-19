//
//  SignUpViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/13/15.
//  Copyright (c) 2015 ProtonMail Reserach. All rights reserved.
//

import Foundation


class SignUpKeyViewController: UIViewController {
    let animationDuration: NSTimeInterval = 0.5
    let buttonDisabledAlpha: CGFloat = 0.5
    let keyboardPadding: CGFloat = 12 - 177
    
    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var passwordInput: TextInsetTextField!
    @IBOutlet weak var confirmInput: TextInsetTextField!
    
    @IBOutlet weak var generateKeypairButton: UIButton!
    
    
    var user_name = "";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupButtons()
        setupInputs()
        
        user_name = sharedUserDataService.username!;
        
        configureNavigationBar()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        dismissKeyboard()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        navigationController?.setNavigationBarHidden(true, animated: true)
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    func setupButtons() {
        generateKeypairButton.alpha = buttonDisabledAlpha
        generateKeypairButton.roundCorners()
    }
    
    func setupInputs()
    {
        passwordInput.roundCorners()
        confirmInput.roundCorners()
    }
    
    // MARK: - private methods
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    func generateKey() {
//        let password = passwordInput.text
//        MBProgressHUD.showHUDAddedTo(view, animated: true)
//        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)) { // 1
//            sharedUserDataService.updateNewUserKeys(password) { _, _, error in
//                dispatch_async(dispatch_get_main_queue()) { // 2
//                    MBProgressHUD.hideHUDForView(self.view, animated: true)
//                    
//                    if let error = error {
//                        let alertController = error.alertController()
//                        alertController.addOKAction()
//                        
//                        self.presentViewController(alertController, animated: true, completion: nil)
//                    } else {
//                        (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
//                    }
//                    
//                }
//            }
//        }
    }
    
    func updateButton(button: UIButton) {
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            button.alpha = button.enabled ? 1.0 : self.buttonDisabledAlpha
        })
    }
    
    func checkInput() -> Bool {
        
        if passwordInput.text.isEmpty {
            return false;
        }
        if confirmInput.text.isEmpty {
            return false;
        }
        
        return true;
    }
    
    func dismissKeyboard() {
        passwordInput.resignFirstResponder()
        confirmInput.resignFirstResponder()
    }
    
    
    // MARK: - Actions
    @IBAction func generateKeyAction(sender: UIButton) {
        generateKey()
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard();
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpKeyViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        
        keyboardPaddingConstraint.constant = 10
        
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

extension SignUpKeyViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        generateKeypairButton.enabled = false
        updateButton(generateKeypairButton)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        generateKeypairButton.enabled = checkInput()
        updateButton(generateKeypairButton)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if checkInput() {
            generateKey()
        }
        
        return true
    }
}