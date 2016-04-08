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
import LocalAuthentication

class SignInViewController: UIViewController {
    
    private let kMailboxSegue = "mailboxSegue"
    private let kSignUpKeySegue = "sign_in_to_sign_up_segue"
    
    private let animationDuration: NSTimeInterval = 0.5
    private let keyboardPadding: CGFloat = 12
    private let buttonDisabledAlpha: CGFloat = 0.5
    private let signUpURL = NSURL(string: "https://protonmail.com/invite")!
    private let forgotPasswordURL = NSURL(string: "https://mail.protonmail.com/help/reset-login-password")!
    
    private let kSegueToSignUpWithNoAnimation = "sign_in_to_splash_no_segue"
    private let kSegueToPinCodeViewNoAnimation = "pin_code_segue"
    
    static var isComeBackFromMailbox = false
    
    var isShowpwd = false;
    var isRemembered = false;
    
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var onePasswordButton: UIButton!
    
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
    
    @IBOutlet weak var loginMidlineConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginWidthConstraint: NSLayoutConstraint!
    
    
    private let secureStore = KeyChainStore()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.performSegueWithIdentifier(kSegueToPinCodeViewNoAnimation, sender: self)
        
        setupTextFields()
        setupButtons()
        
        //check touch id status
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            authenticateUser()
        } else {
            signInIfRememberedCredentials()
            setupView();
        }
    }
    
    func setupView() {
        if(isRemembered)
        {
            HideLoginViews();
        }
        else
        {
            ShowLoginViews();
            if !userCachedStatus.isSplashOk() {
                self.performSegueWithIdentifier(kSegueToSignUpWithNoAnimation, sender: self)
            }
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
    
    @IBAction func onePasswordAction(sender: UIButton) {
        OnePasswordExtension.sharedExtension().findLoginForURLString("https://protonmail.com", forViewController: self, sender: sender, completion: { (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!.code != Int(AppExtensionErrorCodeCancelledByUser) {
                    print("Error invoking Password App Extension for find login: \(error)")
                }
                return
            }
            
            println("\(loginDictionary)")
            
            let username : String! = loginDictionary?[AppExtensionUsernameKey] as? String ?? ""
            let password : String! = loginDictionary?[AppExtensionPasswordKey] as? String ?? ""
            
            self.usernameTextField.text = username
            self.passwordTextField.text = password
            
            //            if let generatedOneTimePassword = loginDictionary?[AppExtensionTOTPKey] as? String {
            //                //self.oneTimePasswordTextField.hidden = false
            //                //self.oneTimePasswordTextField.text = generatedOneTimePassword
            //
            //                // Important: It is recommended that you submit the OTP/TOTP to your validation server as soon as you receive it, otherwise it may expire.
            //                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            //                dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
            //                    self.performSegueWithIdentifier("showThankYouViewController", sender: self)
            //                })
            //            }
            
            if !username.isEmpty && !password.isEmpty {
                self.signIn()
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        
        updateSignInButton(usernameText: usernameTextField.text, passwordText: passwordTextField.text)
        
        if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() == true {
            onePasswordButton.hidden = false
            loginWidthConstraint.constant = 120
            loginMidlineConstraint.constant = -72
        } else {
            onePasswordButton.hidden = true
            loginWidthConstraint.constant = 200
            loginMidlineConstraint.constant = 0
        }
        
        //        let fadeOutTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
        //        dispatch_after(fadeOutTime, dispatch_get_main_queue()) {
        //            UIView.animateWithDuration(0.5, animations: {
        //                let secret = self.secureStore.secret
        //                PMLog.D("\(secret)");
        //                }, completion: {
        //                    _ in
        //                    //  self.secretRetrievalLabel.text = "<placeholder>".
        //                    // PMLog.D("\(secret)")
        //            })
        //        }
    }
    
    func authenticateUser() {
        let savedEmail = userCachedStatus.touchIDEmail
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        var reasonString = "Login: \(savedEmail)"
        
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context .evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: NSError?) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.signInIfRememberedCredentials()
                        self.setupView()
                    }
                }
                else{
                    println(evalPolicyError?.localizedDescription)
                    switch evalPolicyError!.code {
                    case LAError.SystemCancel.rawValue:
                        println("Authentication was cancelled by the system")
                        "Authentication was cancelled by the system".alertToast()
                    case LAError.UserCancel.rawValue:
                        println("Authentication was cancelled by the user")
                    case LAError.UserFallback.rawValue:
                        println("User selected to enter custom password")
                        //self.showPasswordAlert()
                    default:
                        println("Authentication failed")
                        //self.showPasswordAlert()
                        "Authentication failed".alertToast()
                    }
                }
            })]
        }
        else{
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.TouchIDNotEnrolled.rawValue:
                alertString = "TouchID is not enrolled"
            case LAError.PasscodeNotSet.rawValue:
                alertString = "A passcode has not been set"
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = "TouchID not available"
            }
            println(alertString)
            println(error?.localizedDescription)
            alertString.alertToast()
        }
    }
    
    func showPasswordAlert() {
        //ar passwordAlert : UIAlertView = UIAlertView(title: "TouchIDDemo", message: "Please type your password", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Okay")
        //passwordAlert.alertViewStyle = UIAlertViewStyle.SecureTextInput
        //passwordAlert.show()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if sharedUserDataService.isNewUser {
            sharedUserDataService.isNewUser = false
            if sharedUserDataService.isUserCredentialStored {
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
        }
        
        if(SignInViewController.isComeBackFromMailbox)
        {
            ShowLoginViews();
            clean();
        }
        
        if(UIDevice.currentDevice().isLargeScreen() && !isRemembered && userCachedStatus.touchIDEmail.isEmpty)
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
    
    func setupButtons() {
        signInButton.layer.borderColor = UIColor.ProtonMail.Login_Button_Border_Color.CGColor;
        signInButton.alpha = buttonDisabledAlpha
        
        onePasswordButton.layer.borderColor = UIColor.whiteColor().CGColor
        onePasswordButton.layer.borderWidth = 2
    }
    
    func signIn() {
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        isRemembered = true
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            clean();
        }
        SignInViewController.isComeBackFromMailbox = false
        
        var username = (usernameTextField.text ?? "").trim()
        var password = (passwordTextField.text ?? "").trim()
        
        
        //        let fadeOutTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
        //        dispatch_after(fadeOutTime, dispatch_get_main_queue()) {
        //            UIView.animateWithDuration(0.5, animations: {
        //                self.secureStore.secret = "This is a test secret";
        //                }, completion: {
        //                    _ in
        //                    //  self.secretRetrievalLabel.text = "<placeholder>".
        //                    // PMLog.D("\(secret)")
        //            })
        //        }
        //
        //
        //        let fadeOutTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
        //        dispatch_after(fadeOutTime, dispatch_get_main_queue()) {
        //            UIView.animateWithDuration(0.5, animations: {
        //                let secret = self.secureStore.secret
        //                PMLog.D("\(secret)");
        //                }, completion: {
        //                    _ in
        //                    //  self.secretRetrievalLabel.text = "<placeholder>".
        //                    // PMLog.D("\(secret)")
        //            })
        //        }
        
        //        self.secureStore.secret = "This is a test secret";
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
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefined.didSignIn, object: self)
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