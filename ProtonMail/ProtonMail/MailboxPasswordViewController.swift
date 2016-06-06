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
    @IBOutlet weak var backgroundImage: UIImageView!

    @IBOutlet weak var passwordManagerButton: UIButton!
    var isRemembered: Bool = sharedUserDataService.isRememberMailboxPassword
    var isShowpwd : Bool = false;
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var passwordTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var decryptWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var decryptMidConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDecryptButton()
        
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "MAILBOX PASSWORD", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#cecaca")])
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        passwordTopPaddingConstraint.priority = level
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        
        if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() == true {
            passwordManagerButton.hidden = false
            decryptWidthConstraint.constant = 120
            decryptMidConstraint.constant = -72
        } else {
            passwordManagerButton.hidden = true
            decryptWidthConstraint.constant = 200
            decryptMidConstraint.constant = 0
        }
        
        if let pwdTxt = passwordTextField.text {
            decryptButton.enabled = !pwdTxt.isEmpty
            updateButton(decryptButton)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if(UIDevice.currentDevice().isLargeScreen())
        {
            passwordTextField.becomeFirstResponder()
        }
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if (parent == nil) {
            SignInViewController.isComeBackFromMailbox = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        navigationController?.setNavigationBarHidden(true, animated: true)
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)!
    }
    
    func setupDecryptButton() {
        decryptButton.layer.borderColor = UIColor.ProtonMail.Login_Button_Border_Color.CGColor;
        decryptButton.alpha = buttonDisabledAlpha
        
        passwordManagerButton.layer.borderColor = UIColor.whiteColor().CGColor
        passwordManagerButton.layer.borderWidth = 2
    }
    
    
    // MARK: - private methods
    
    @IBAction func onePasswordAction(sender: UIButton) {
        OnePasswordExtension.sharedExtension().findLoginForURLString("https://protonmail.com", forViewController: self, sender: sender, completion: { (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
                    print("Error invoking Password App Extension for find login: \(error)")
                }
                return
            }
            PMLog.D("\(loginDictionary)")
            //_ = (loginDictionary?[AppExtensionUsernameKey] as? String ?? "").trim()
            let password : String! = (loginDictionary?[AppExtensionPasswordKey] as? String ?? "").trim()
            
            self.passwordTextField.text = password
            
            if !password.isEmpty {
                self.decryptButton.enabled = !password.isEmpty
                self.updateButton(self.decryptButton)
                self.decryptPassword()
            }
        })
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    func decryptPassword() {
        isRemembered = true
        let password = (passwordTextField.text ?? "").trim()
        if sharedUserDataService.isMailboxPasswordValid(password, privateKey: AuthCredential.getPrivateKey()) {
            if sharedUserDataService.isSet {
                sharedUserDataService.setMailboxPassword(password, isRemembered: self.isRemembered)
                (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            } else {
                do {
                    try AuthCredential.setupToken(password, isRememberMailbox: self.isRemembered)
                    MBProgressHUD.showHUDAddedTo(view, animated: true)
                    sharedLabelsDataService.fetchLabels()
                    sharedUserDataService.fetchUserInfo() { info, error in
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        if error != nil {
                            let alertController = error!.alertController()
                            alertController.addOKAction()
                            self.presentViewController(alertController, animated: true, completion: nil)
                            if error!.domain == APIServiceErrorDomain && error!.code == APIErrorCode.AuthErrorCode.localCacheBad {
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        } else if info != nil {
                            if info!.delinquent < 3 {
                                sharedUserDataService.setMailboxPassword(password, isRemembered: self.isRemembered)
                                self.loadContent()
                                self.restoreBackup();
                                NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefined.didSignIn, object: self)
                            } else {
                                let alertController = NSLocalizedString("Access to this account is disabled due to non-payment. Please sign in through protonmail.com to pay your unpaid invoice.").alertController() //here needs change to a clickable link
                                alertController.addAction(UIAlertAction.okAction({ (action) -> Void in
                                    self.navigationController?.popViewControllerAnimated(true)
                                }))
                                self.presentViewController(alertController, animated: true, completion: nil)
                            }
                        } else {
                            let alertController = NSError.unknowError().alertController()
                            alertController.addOKAction()
                            self.presentViewController(alertController, animated: true, completion: nil)
                        }
                    }
                } catch let ex as NSError {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    let message = (ex.userInfo["MONExceptionReason"] as? String) ?? NSLocalizedString("The mailbox password is incorrect.")
                    let alertController = UIAlertController(title: NSLocalizedString("Incorrect password"), message: NSLocalizedString(message),preferredStyle: .Alert)
                    alertController.addOKAction()
                    presentViewController(alertController, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Incorrect password"), message: NSLocalizedString("The mailbox password is incorrect."), preferredStyle: .Alert)
            alert.addAction((UIAlertAction.okAction()))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func restoreBackup () {
        UserTempCachedStatus.restore()
    }
    
    private func loadContent() {
        self.loadContactsAfterInstall()
        (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
    }
    
    func loadContactsAfterInstall()
    {
        sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
            if error != nil {
                NSLog("\(error)")
            } else {
                NSLog("Contacts count: \(contacts!.count)")
            }
        })
    }
    
    func updateButton(button: UIButton) {
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            button.alpha = button.enabled ? 1.0 : self.buttonDisabledAlpha
        })
    }
    
    
    // MARK: - Actions
    @IBOutlet weak var resetMailboxPasswordAction: UIButton!
    @IBAction func resetMBPAction(sender: AnyObject) {
        let alert = UIAlertController(title: NSLocalizedString("Alert"), message: NSLocalizedString("To reset your mailbox password, please use the web version of ProtonMail at protonmail.com"), preferredStyle: .Alert)
        alert.addAction((UIAlertAction.okAction()))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func decryptAction(sender: UIButton) {
        decryptPassword()
    }
    
    @IBAction func rememberButtonAction(sender: UIButton) {
        self.isRemembered = !isRemembered
        self.isRemembered = true;
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        passwordTextField.resignFirstResponder()
    }
    
    @IBAction func backAction(sender: UIButton) {
        navigationController?.popViewControllerAnimated(true);
    }
    @IBAction func showAction(sender: UIButton) {
        self.isShowpwd = !isShowpwd
        sender.selected = isShowpwd
        
        if isShowpwd {
            self.passwordTextField.secureTextEntry = false;
        } else {
            self.passwordTextField.secureTextEntry = true;
        }
        
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension MailboxPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        configConstraint(false)
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
        configConstraint(true)
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
        let text = textField.text as NSString!
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == passwordTextField {
            decryptButton.enabled = !changedText.isEmpty
        }
        updateButton(decryptButton)
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let pwd = (passwordTextField.text ?? "").trim()
        if !pwd.isEmpty {
            decryptPassword()
        }
        return true
    }
}
