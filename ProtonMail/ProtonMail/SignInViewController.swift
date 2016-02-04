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
import Fabric
import Crashlytics

class SignInViewController: UIViewController {
    
    private let kMailboxSegue = "mailboxSegue"
    private let kSignUpKeySegue = "sign_in_to_sign_up_segue"

    
    private let animationDuration: NSTimeInterval = 0.5
    private let keyboardPadding: CGFloat = 12
    private let buttonDisabledAlpha: CGFloat = 0.5
    private let signUpURL = NSURL(string: "https://protonmail.com/invite")!
    private let forgotPasswordURL = NSURL(string: "https://mail.protonmail.com/help/reset-login-password")!
    
    static var isComeBackFromMailbox = false
    
    var isShowpwd = false;
    var isRemembered = false;
    
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    
    //@IBOutlet weak var signUpButton: UIButton!
    //@IBOutlet weak var forgotButton: UIButton!
    //@IBOutlet weak var rememberButton: UIButton!
    
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    // Constraints
    @IBOutlet weak var userLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var userTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userNameTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    struct Notification {
        static let didSignOut = "UserDataServiceDidSignOutNotification"
        static let didSignIn = "UserDataServiceDidSignInNotification"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTextFields()
        
        setupSignInButton()
        signInIfRememberedCredentials()
        
        if(isRemembered)
        {
            HideLoginViews();
        }
        else
        {
            ShowLoginViews();
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return  Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        userLeftPaddingConstraint.priority = level
        userTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        logoTopPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
    }
    
    @IBAction func showPasswordAction(sender: UIButton) {
        isShowpwd = !isShowpwd
        sender.selected = isShowpwd
        
        if isShowpwd {
            self.passwordTextField.secureTextEntry = false;
        } else {
            self.passwordTextField.secureTextEntry = true;
        }
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if (!(parent?.isEqual(self.parentViewController) ?? false)) {
        }
        
        if(SignInViewController.isComeBackFromMailbox)
        {
            ShowLoginViews();
            clean();
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        
        updateSignInButton(usernameText: usernameTextField.text, passwordText: passwordTextField.text)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if(SignInViewController.isComeBackFromMailbox)
        {
            ShowLoginViews();
            clean();
        }
        
        if(UIDevice.currentDevice().isLargeScreen() && !isRemembered)
        {
            usernameTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSignUpKeySegue {
            let viewController = segue.destinationViewController as! SignUpUserNameViewController
            viewController.viewModel = SignupViewModelImpl()
        }
    }
    
    // MARK: - Private methods
    
    private func HideLoginViews()
    {
        self.usernameView.alpha = 0.0
        self.passwordView.alpha = 0.0
        self.signInButton.alpha = 0.0
    }
    
    private func ShowLoginViews()
    {
        sharedPushNotificationService.unregisterForRemoteNotifications()
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.usernameView.alpha = 1.0
            self.passwordView.alpha = 1.0
            self.signInButton.alpha = 1.0
            
            }, completion: { finished in
        })
    }
    
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    internal func setupTextFields() {
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "Username", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#cecaca")])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#cecaca")])
    }
    
    func setupSignInButton() {
        signInButton.layer.borderColor = UIColor.ProtonMail.Login_Button_Border_Color.CGColor;
        signInButton.alpha = buttonDisabledAlpha
    }
    
    func signIn() {
        
        isRemembered = true
        
        SignInViewController.isComeBackFromMailbox = false
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        
        var username = (usernameTextField.text ?? "").trim();
        var password = (passwordTextField.text ?? "").trim();
        
        sharedUserDataService.signIn(username, password: password, isRemembered: isRemembered) { _, error in
            MBProgressHUD.hideHUDForView(self.view, animated: true)
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
                self.ShowLoginViews();
                let alertController = error.alertController()
                alertController.addOKAction()
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                self.loadContent()
            }
        }
    }
    
    func signInIfRememberedCredentials() {
        if sharedUserDataService.isUserCredentialStored {
            sharedUserDataService.isSignedIn = true
            isRemembered = true
            
            if let addresses = sharedUserDataService.userInfo?.userAddresses.toPMNAddresses() {
                sharedOpenPGP.setAddresses(addresses);
            }
            
            usernameTextField.text = sharedUserDataService.username
            passwordTextField.text = sharedUserDataService.password
            
            self.loadContent()
        }
        else
        {
            clean()
        }
    }
    
    func logUser() {
        if  let username = sharedUserDataService.username {
            Crashlytics.sharedInstance().setUserIdentifier(username)
            Crashlytics.sharedInstance().setUserName(username)
        }
    }
    
    private func loadContent() {
        logUser()
        if sharedUserDataService.isMailboxPasswordStored {
            NSNotificationCenter.defaultCenter().postNotificationName(Notification.didSignIn, object: self)
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            loadContactsAfterInstall()
        } else {
            //if count(AuthCredential.getPrivateKey().trim()) > 10 {
            self.performSegueWithIdentifier(self.kMailboxSegue, sender: self)
            //            }
            //            else {
            //                self.performSegueWithIdentifier(self.signUpKeySegue, sender: self)
            //            }
        }
    }
    
    func loadContactsAfterInstall()
    {
        sharedUserDataService.fetchUserInfo()
        sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
            if error != nil {
                NSLog("\(error)")
            } else {
                NSLog("Contacts count: \(contacts!.count)")
            }
        })
    }
    
    
    func clean()
    {
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded();
    }
    
    
    func updateSignInButton(#usernameText: String, passwordText: String) {
        signInButton.enabled = !usernameText.isEmpty && !passwordText.isEmpty
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            
            if (self.signInButton.alpha != 0.0) {
                self.signInButton.alpha = self.signInButton.enabled ? 1.0 : self.buttonDisabledAlpha
            }
        })
    }
    
    // MARK: - Actions
    
    @IBAction func rememberButtonAction(sender: UIButton) {
        isRemembered = !isRemembered
        
        isRemembered = true
        
    }
    
    
    @IBAction func signInAction(sender: UIButton) {
        dismissKeyboard()
        signIn()
    }
    
    
    @IBAction func fogorPasswordAction(sender: AnyObject) {
        dismissKeyboard()
        UIApplication.sharedApplication().openURL(forgotPasswordURL)
    }
    
    @IBAction func signUpAction(sender: UIButton) {
        dismissKeyboard()
        self.performSegueWithIdentifier(kSignUpKeySegue, sender: self)
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignInViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        self.configConstraint(false)
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
        self.configConstraint(true)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldClear(textField: UITextField) -> Bool {
        updateSignInButton(usernameText: "", passwordText: "")
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == usernameTextField {
            updateSignInButton(usernameText: changedText, passwordText: passwordTextField.text)
        } else if textField == passwordTextField {
            updateSignInButton(usernameText: usernameTextField.text, passwordText: changedText)
        }
        
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