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


enum SignInUIFlow : Int {
    case RequirePin = 0
    case RequireTouchID = 1
    case Restore = 2
}

class SignInViewController: ProtonMailViewController {
    
    private let kMailboxSegue = "mailboxSegue"
    private let kSignUpKeySegue = "sign_in_to_sign_up_segue"
    
    private let animationDuration: NSTimeInterval = 0.5
    private let keyboardPadding: CGFloat = 12
    private let buttonDisabledAlpha: CGFloat = 0.5
    private let signUpURL = NSURL(string: "https://protonmail.com/invite")!
    private let forgotPasswordURL = NSURL(string: "https://mail.protonmail.com/help/reset-login-password")!
    
    private let kSegueToSignUpWithNoAnimation = "sign_in_to_splash_no_segue"
    private let kSegueToPinCodeViewNoAnimation = "pin_code_segue"
    private let kSegueTo2FACodeSegue = "2fa_code_segue"
    
    static var isComeBackFromMailbox = false
    
    var isShowpwd = false;
    var isRemembered = false;
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInLabel: UILabel!
    
    @IBOutlet weak var onePasswordButton: UIButton!
    
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
    
    @IBOutlet weak var signUpTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var touchIDButton: UIButton!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideTouchID(false)
        setupTextFields()
        setupButtons()
        setupVersionLabel()
        
        let signinFlow = getViewFlow()
        switch signinFlow {
        case .RequirePin:
            self.performSegueWithIdentifier(kSegueToPinCodeViewNoAnimation, sender: self)
            break
        case .RequireTouchID:
            showTouchID(false)
            authenticateUser()
            break
        case .Restore:
            signInIfRememberedCredentials()
            setupView();
            break
        }
    }
    
    
    private func setupVersionLabel () {
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
                versionLabel.text = NSLocalizedString("v") + version + "(\(build))"
            } else {
                versionLabel.text = NSLocalizedString("v") + version
            }
        } else {
            versionLabel.text = NSLocalizedString("")
        }
    }
    
    private func getViewFlow() -> SignInUIFlow {
        if sharedTouchID.showTouchIDOrPin() {
            if userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty {
                return SignInUIFlow.RequirePin
            } else {
                //check touch id status
                if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                    return SignInUIFlow.RequireTouchID
                } else {
                    return SignInUIFlow.Restore
                }
            }
        } else {
            return SignInUIFlow.Restore
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
    
    internal func showTouchID(animated : Bool = true) {
        touchIDButton.layer.cornerRadius = 25
        touchIDButton.hidden = false
        signUpTopConstraint.priority = 1
        UIView.animateWithDuration(animated ? 0.25 : 0, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    internal func hideTouchID(animated : Bool = true) {
        touchIDButton.layer.cornerRadius = 25
        touchIDButton.hidden = true
        signUpTopConstraint.priority = 750
        UIView.animateWithDuration(animated ? 0.25 : 0, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
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
    
    @IBAction func touchIDAction(sender: UIButton) {
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            authenticateUser()
        } else {
            hideTouchID()
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
            
            PMLog.D("\(loginDictionary)")
            
            let username : String! = (loginDictionary?[AppExtensionUsernameKey] as? String ?? "").trim()
            let password : String! = (loginDictionary?[AppExtensionPasswordKey] as? String ?? "") //.trim()
            
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
                self.updateSignInButton(usernameText: username, passwordText: password)
                self.signIn()
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        
        let uName = (usernameTextField.text ?? "").trim()
        let pwd = (passwordTextField.text ?? "") //.trim()
        
        updateSignInButton(usernameText: uName, passwordText: pwd)
        
        if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() == true {
            onePasswordButton.hidden = false
            loginWidthConstraint.constant = 120
            loginMidlineConstraint.constant = -72
        } else {
            onePasswordButton.hidden = true
            loginWidthConstraint.constant = 200
            loginMidlineConstraint.constant = 0
        }
    }
    
    func authenticateUser() {
        let savedEmail = userCachedStatus.touchIDEmail
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "Login: \(savedEmail)"
        
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: NSError?) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.signInIfRememberedCredentials()
                        self.setupView()
                    }
                }
                else{
                    dispatch_async(dispatch_get_main_queue()) {
                        PMLog.D("\(evalPolicyError?.localizedDescription)")
                        switch evalPolicyError!.code {
                        case LAError.SystemCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the system")
                            NSLocalizedString("Authentication was cancelled by the system").alertToast()
                        case LAError.UserCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the user")
                        case LAError.UserFallback.rawValue:
                            PMLog.D("User selected to enter custom password")
                        default:
                            PMLog.D("Authentication failed")
                            NSLocalizedString("Authentication failed").alertToast()
                        }
                    }
                }
            })]
        }
        else{
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.TouchIDNotEnrolled.rawValue:
                alertString = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings")
            case LAError.PasscodeNotSet.rawValue:
                alertString = NSLocalizedString("A passcode has not been set, enable it in the system Settings")
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = NSLocalizedString("TouchID not available")
            }
            PMLog.D(alertString)
            PMLog.D("\(error?.localizedDescription)")
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
        } else if segue.identifier == kSegueToPinCodeViewNoAnimation {
            let viewController = segue.destinationViewController as! PinCodeViewController
            viewController.viewModel = UnlockPinCodeModelImpl()
            viewController.delegate = self
        } else if segue.identifier == kSegueTo2FACodeSegue {
            let popup = segue.destinationViewController as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .TwoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    // MARK: - Private methods
    
    private func HideLoginViews()
    {
        self.usernameView.alpha = 0.0
        self.passwordView.alpha = 0.0
        self.signInButton.alpha = 0.0
        self.onePasswordButton.alpha = 0.0
    }
    
    private func ShowLoginViews()
    {
        sharedPushNotificationService.unregisterForRemoteNotifications()
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.usernameView.alpha = 1.0
            self.passwordView.alpha = 1.0
            self.signInButton.alpha = 1.0
            self.onePasswordButton.alpha = 1.0
            
            }, completion: { finished in
        })
    }
    
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    internal func setupTextFields() {
        usernameTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Username", comment: "Title"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#cecaca")])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Password", comment: "Title"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#cecaca")])
    }
    
    func setupButtons() {
        signInButton.layer.borderColor = UIColor.ProtonMail.Login_Button_Border_Color.CGColor;
        signInButton.alpha = buttonDisabledAlpha
        
        onePasswordButton.layer.borderColor = UIColor.whiteColor().CGColor
        onePasswordButton.layer.borderWidth = 2
    }
    
    private var cachedTwoCode : String?
    func signIn() {
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        isRemembered = true
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            clean();
        }
        
        SignInViewController.isComeBackFromMailbox = false
        
        let username = (usernameTextField.text ?? "").trim()
        let password = (passwordTextField.text ?? "") //.trim()
        
        
        //need pass twoFACode
        sharedUserDataService.signIn(username, password: password, twoFACode: cachedTwoCode,
            ask2fa: {
            //2fa
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
                self.performSegueWithIdentifier(self.kSegueTo2FACodeSegue, sender: self)
            },
            onError: { (error) in
                //error
                self.cachedTwoCode = nil
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                PMLog.D("error: \(error)")
                self.ShowLoginViews();
                let alertController = error.alertController()
                alertController.addOKAction()
                self.presentViewController(alertController, animated: true, completion: nil)
            },
            onSuccess: { (mailboxpwd) in
                //ok
                self.cachedTwoCode = nil
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                if mailboxpwd != nil {
                    self.decryptPassword(mailboxpwd!)
                } else {
                    self.restoreBackup()
                    self.loadContent()
                }
            })
    }
    
    func decryptPassword(mailboxPassword:String!) {
        isRemembered = true
        if sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: AuthCredential.getPrivateKey()) {
            if sharedUserDataService.isSet {
                sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: self.isRemembered)
                (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            } else {
                do {
                    try AuthCredential.setupToken(mailboxPassword, isRememberMailbox: self.isRemembered)
                    MBProgressHUD.showHUDAddedTo(view, animated: true)
                    sharedLabelsDataService.fetchLabels()
                    sharedUserDataService.fetchUserInfo() { info, _, error in
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
                                userCachedStatus.pinFailedCount = 0;
                                sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: self.isRemembered)
                                self.restoreBackup()
                                self.loadContent()
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
    
    func signInIfRememberedCredentials() {
        if sharedUserDataService.isUserCredentialStored {
            userCachedStatus.lockedApp = false
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
            UserTempCachedStatus.clearFromKeychain()
            userCachedStatus.pinFailedCount = 0;
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefined.didSignIn, object: self)
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            loadContactsAfterInstall()
        } else {
            self.performSegueWithIdentifier(self.kMailboxSegue, sender: self)
        }
    }
    
    func loadContactsAfterInstall()
    {
        sharedUserDataService.fetchUserInfo()
        sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
            if error != nil {
                PMLog.D("\(error)")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        })
    }
    
    func clean()
    {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
    func updateSignInButton(usernameText usernameText: String, passwordText: String) {
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

extension SignInViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(code: String, pwd : String) {
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        self.cachedTwoCode = code
        self.signIn()
    }

    func Cancel2FA() {
        sharedUserDataService.twoFactorStatus = 0
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
}

extension SignInViewController : PinCodeViewControllerDelegate {
    
    func Cancel() {
        UserTempCachedStatus.backup()
        clean()
    }
    
    func Next() {
        signInIfRememberedCredentials()
        setupView();
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
        let text = textField.text! as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == usernameTextField {
            updateSignInButton(usernameText: changedText, passwordText: passwordTextField.text!)
        } else if textField == passwordTextField {
            updateSignInButton(usernameText: usernameTextField.text!, passwordText: changedText)
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        let uName = (usernameTextField.text ?? "").trim()
        let pwd = (passwordTextField.text ?? "") //.trim()
        
        if !uName.isEmpty && !pwd.isEmpty {
            signIn()
        }
        
        return true
    }
}
