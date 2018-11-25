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
import MBProgressHUD


//class SignInViewController: BaseViewController {
class SignInViewController: ProtonMailViewController {
    static var isComeBackFromMailbox                = false
    
    private var showingTouchID                      = false
    
    fileprivate let animationDuration: TimeInterval = 0.5
    fileprivate let keyboardPadding: CGFloat        = 12
    fileprivate let buttonDisabledAlpha: CGFloat    = 0.5
    
    fileprivate let kMailboxSegue                   = "mailboxSegue"
    fileprivate let kSignUpKeySegue                 = "sign_in_to_sign_up_segue"
    fileprivate let kSegueToSignUpWithNoAnimation   = "sign_in_to_splash_no_segue"
    fileprivate let kSegueToPinCodeViewNoAnimation  = "pin_code_segue"
    fileprivate let kSegueTo2FACodeSegue            = "2fa_code_segue"
    
    private var isShowpwd                           = false;
    private var isRemembered                        = false;
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority  = UILayoutPriority(rawValue: 750.0);
    
    //views
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var signInTitle: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var forgotPwdButton: UIButton!
    @IBOutlet weak var languagesLabel: UILabel!
    
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
        case .requirePin:
            sharedUserDataService.isSignedIn = false
            self.performSegue(withIdentifier: kSegueToPinCodeViewNoAnimation, sender: self)
            break
        case .requireTouchID:
            sharedUserDataService.isSignedIn = false
            showTouchID(false)
            authenticateUser()
            break
        case .restore:
            signInIfRememberedCredentials()
            setupView();
            break
        }
    }
    
    @IBAction func changeLanguagesAction(_ sender: UIButton) {
        let current_language = LanguageManager.currentLanguageEnum()
        let title = LocalString._settings_current_language_is + current_language.description
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        for l in ELanguage.allItems() {
            if l != current_language {
                alertController.addAction(UIAlertAction(title: l.nativeDescription, style: .default, handler: { (action) -> Void in
                    let _ = self.navigationController?.popViewController(animated: true)
                    LanguageManager.saveLanguage(byCode: l.code)
                    LocalizedString.reset()
                    UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
                        self.setupTextFields()
                        self.setupButtons()
                        self.setupVersionLabel()
                        self.view.layoutIfNeeded()
                    }, completion: nil)

                }))
            }
        }
        
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func setupVersionLabel () {
        let language: ELanguage =  LanguageManager.currentLanguageEnum()
        languagesLabel.text = language.description
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                versionLabel.text = "v" + version + "(\(build))"
            } else {
                versionLabel.text = "v" + version
            }
        } else {
            versionLabel.text = ""
        }
    }
    
    fileprivate func getViewFlow() -> SignInUIFlow {
        if sharedTouchID.showTouchIDOrPin() {
            if userCachedStatus.isPinCodeEnabled && !userCachedStatus.pinCode.isEmpty {
                return SignInUIFlow.requirePin
            } else {
                //check touch id status
                if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
                    return SignInUIFlow.requireTouchID
                } else {
                    return SignInUIFlow.restore
                }
            }
        } else {
            return SignInUIFlow.restore
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
                self.performSegue(withIdentifier: kSegueToSignUpWithNoAnimation, sender: self)
            }
        }
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    internal func showTouchID(_ animated : Bool = true) {
        touchIDButton.layer.cornerRadius = 25
        touchIDButton.isHidden = false
        signUpTopConstraint.priority = UILayoutPriority(rawValue: 1)
        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    internal func hideTouchID(_ animated : Bool = true) {
        touchIDButton.layer.cornerRadius = 25
        touchIDButton.isHidden = true
        signUpTopConstraint.priority = UILayoutPriority(rawValue: 750)
        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        userLeftPaddingConstraint.priority = level
        userTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        logoTopPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
    }
    
    @IBAction func showPasswordAction(_ sender: UIButton) {
        isShowpwd = !isShowpwd
        sender.isSelected = isShowpwd
        
        if isShowpwd {
            self.passwordTextField.isSecureTextEntry = false;
        } else {
            self.passwordTextField.isSecureTextEntry = true;
        }
    }
    
    @IBAction func touchIDAction(_ sender: UIButton) {
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            authenticateUser()
        } else {
            hideTouchID()
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if (!(parent?.isEqual(self.parent) ?? false)) {
        }
        
        if(SignInViewController.isComeBackFromMailbox)
        {
            ShowLoginViews();
            clean();
        }
    }
    
    @IBAction func onePasswordAction(_ sender: UIButton) {
        OnePasswordExtension.shared().findLogin(forURLString: "https://protonmail.com",
                                                for: self,
                                                sender: sender,
                                                completion: { (loginDictionary, error) -> Void in
            if loginDictionary == nil {
                if error!._code != Int(AppExtensionErrorCodeCancelledByUser) {
                    PMLog.D("Error invoking Password App Extension for find login: \(String(describing: error))")
                }
                return
            }
            
            let username : String! = (loginDictionary?[AppExtensionUsernameKey] as? String ?? "").trim()
            let password : String! = (loginDictionary?[AppExtensionPasswordKey] as? String ?? "")
            
            self.usernameTextField.text = username
            self.passwordTextField.text = password
            
            if !username.isEmpty && !password.isEmpty {
                self.updateSignInButton(usernameText: username, passwordText: password)
                self.signIn()
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NotificationCenter.default.addKeyboardObserver(self)
        NotificationCenter.default.addObserver(self, selector:#selector(SignInViewController.doEnterForeground), name:  UIApplication.willEnterForegroundNotification, object: nil)
        let uName = (usernameTextField.text ?? "").trim()
        let pwd = (passwordTextField.text ?? "") //.trim()
        
        updateSignInButton(usernameText: uName, passwordText: pwd)
        
        if OnePasswordExtension.shared().isAppExtensionAvailable() == true {
            onePasswordButton.isHidden = false
            loginWidthConstraint.constant = 120
            loginMidlineConstraint.constant = -72
        } else {
            onePasswordButton.isHidden = true
            loginWidthConstraint.constant = 200
            loginMidlineConstraint.constant = 0
        }
    }
    
    @objc func doEnterForeground() {
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            authenticateUser()
        }
    }
    
    func authenticateUser() {
        if !showingTouchID {
            showingTouchID = true
        } else {
            return
        }
        let savedEmail = userCachedStatus.codedEmail()
        // Get the local authentication context.
        let context = LAContext()
        // Declare a NSError variable.
        var error: NSError?
        context.localizedFallbackTitle = ""
        // Set the reason string that will appear on the authentication alert.
        let reasonString = "\(LocalString._general_login): \(savedEmail)"
        // Check if the device can evaluate the policy.
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: Error?) in
                self.showingTouchID = false
                if success {
                    DispatchQueue.main.async {
                        self.signInIfRememberedCredentials()
                        self.setupView()
                    }
                }
                else{
                    DispatchQueue.main.async {
                        switch evalPolicyError!._code {
                        case LAError.Code.systemCancel.rawValue:
                            LocalString._authentication_was_cancelled_by_the_system.alertToast()
                        case LAError.Code.userCancel.rawValue:
                            PMLog.D("Authentication was cancelled by the user")
                        case LAError.Code.userFallback.rawValue:
                            PMLog.D("User selected to enter custom password")
                        default:
                            PMLog.D("Authentication failed")
                           LocalString._authentication_failed.alertToast()
                        }
                    }
                }
            })
        }
        else{
            showingTouchID = false
            var alertString : String = "";
            // If the security policy cannot be evaluated then show a short message depending on the error.
            switch error!.code{
            case LAError.Code.touchIDNotEnrolled.rawValue:
                alertString = LocalString._general_touchid_not_enrolled
            case LAError.Code.passcodeNotSet.rawValue:
                alertString = LocalString._general_passcode_not_set
            case -6:
                alertString = error?.localizedDescription ?? LocalString._general_touchid_not_available
                break
            default:
                // The LAError.TouchIDNotAvailable case.
                alertString = LocalString._general_touchid_not_available
            }
            alertString.alertToast()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        
        if(UIDevice.current.isLargeScreen() && !isRemembered && userCachedStatus.touchIDEmail.isEmpty)
        {
            usernameTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSignUpKeySegue {
            let viewController = segue.destination as! SignUpUserNameViewController
            viewController.viewModel = SignupViewModelImpl()
        } else if segue.identifier == kSegueToPinCodeViewNoAnimation {
            let viewController = segue.destination as! PinCodeViewController
            viewController.viewModel = UnlockPinCodeModelImpl()
            viewController.delegate = self
        } else if segue.identifier == kSegueTo2FACodeSegue {
            let popup = segue.destination as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .twoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    // MARK: - Private methods
    
    fileprivate func HideLoginViews()
    {
        self.usernameView.alpha      = 0.0
        self.passwordView.alpha      = 0.0
        self.signInButton.alpha      = 0.0
        self.onePasswordButton.alpha = 0.0
    }
    
    fileprivate func ShowLoginViews() {
        sharedPushNotificationService.unregisterForRemoteNotifications()
        UIView.animate(withDuration: 1.0, animations: { () -> Void in
            self.usernameView.alpha      = 1.0
            self.passwordView.alpha      = 1.0
            self.signInButton.alpha      = 1.0
            self.onePasswordButton.alpha = 1.0
        }, completion: { finished in
                        
        })
    }
    
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    internal func setupTextFields() {
        PMLog.D(LocalString._user_login)
        signInTitle.text = LocalString._user_login
        
        usernameTextField.attributedPlaceholder = NSAttributedString(string: LocalString._username,
                                                                     attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#cecaca")])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: LocalString._password,
                                                                     attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#cecaca")])
    }
    
    func setupButtons() {
        signInButton.layer.borderColor      = UIColor.ProtonMail.Login_Button_Border_Color.cgColor;
        signInButton.alpha                  = buttonDisabledAlpha
        
        onePasswordButton.layer.borderColor = UIColor.white.cgColor
        onePasswordButton.layer.borderWidth = 2
        
        signInButton.setTitle(LocalString._general_login, for: .normal)
        
        signUpButton.setTitle(LocalString._need_an_account_sign_up, for: .normal)
        forgotPwdButton.setTitle(LocalString._forgot_password, for: .normal)
        
        
        if biometricType == .faceID {
            self.touchIDButton.setImage(UIImage(named: "face_id_icon"), for: .normal)
        }
        
    }
    
    fileprivate var cachedTwoCode : String?
    func signIn() {
        MBProgressHUD.showAdded(to: view, animated: true)
        isRemembered = true
        if (!userCachedStatus.touchIDEmail.isEmpty && userCachedStatus.isTouchIDEnabled) {
            clean();
        }
        
        SignInViewController.isComeBackFromMailbox = false
        
        let username = (usernameTextField.text ?? "").trim()
        let password = (passwordTextField.text ?? "")
        
        
        //need pass twoFACode
        sharedUserDataService.signIn(username, password: password, twoFACode: cachedTwoCode,
            ask2fa: {
            //2fa
                MBProgressHUD.hide(for: self.view, animated: true)
                NotificationCenter.default.removeKeyboardObserver(self)
                self.performSegue(withIdentifier: self.kSegueTo2FACodeSegue, sender: self)
            },
            onError: { (error) in
                //error
                self.cachedTwoCode = nil
                MBProgressHUD.hide(for: self.view, animated: true)
                PMLog.D("error: \(error)")
                self.ShowLoginViews();
                if !error.code.forceUpgrade {
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                }
            },
            onSuccess: { (mailboxpwd) in
                //ok
                self.cachedTwoCode = nil
                MBProgressHUD.hide(for: self.view, animated: true)
                if mailboxpwd != nil {
                    self.decryptPassword(mailboxpwd!)
                } else {
                    self.restoreBackup()
                    self.loadContent()
                }
            })
    }
    
    func decryptPassword(_ mailboxPassword:String!) {
        isRemembered = true
        if sharedUserDataService.isMailboxPasswordValid(mailboxPassword, privateKey: AuthCredential.getPrivateKey()) {
            if sharedUserDataService.isSet {
                sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: self.isRemembered)
                (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            } else {
                do {
                    try AuthCredential.setupToken(mailboxPassword, isRememberMailbox: self.isRemembered)
                    MBProgressHUD.showAdded(to: view, animated: true)
                    sharedLabelsDataService.fetchLabels()
                    ServicePlanDataService.shared.updateCurrentSubscription()
                    sharedUserDataService.fetchUserInfo().done(on: .main) { info in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if info != nil {
                            if info!.delinquent < 3 {
                                userCachedStatus.pinFailedCount = 0;
                                sharedUserDataService.setMailboxPassword(mailboxPassword, keysalt: nil, isRemembered: self.isRemembered)
                                self.restoreBackup()
                                self.loadContent()
                                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: self)
                            } else {
                                let alertController = LocalString._general_account_disabled_non_payment.alertController()
                                alertController.addAction(UIAlertAction.okAction({ (action) -> Void in
                                    let _ = self.navigationController?.popViewController(animated: true)
                                }))
                                self.present(alertController, animated: true, completion: nil)
                            }
                        } else {
                            let alertController = NSError.unknowError().alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }.catch(on: .main) { (error) in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if let error = error as NSError? {
                            let alertController = error.alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                            if error.domain == APIServiceErrorDomain && error.code == APIErrorCode.AuthErrorCode.localCacheBad {
                                let _ = self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                } catch let ex as NSError {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let message = (ex.userInfo["MONExceptionReason"] as? String) ?? LocalString._the_mailbox_password_is_incorrect
                    let alertController = UIAlertController(title: LocalString._incorrect_password, message: NSLocalizedString(message, comment: ""),preferredStyle: .alert)
                    alertController.addOKAction()
                    present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController(title: LocalString._incorrect_password, message: LocalString._the_mailbox_password_is_incorrect, preferredStyle: .alert)
            alert.addAction((UIAlertAction.okAction()))
            present(alert, animated: true, completion: nil)
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
    
    fileprivate func loadContent() {
        logUser()
        if sharedUserDataService.isMailboxPasswordStored {
            UserTempCachedStatus.clearFromKeychain()
            userCachedStatus.pinFailedCount = 0;
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: self)
            (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            loadContactsAfterInstall()
        } else {
            self.performSegue(withIdentifier: self.kMailboxSegue, sender: self)
        }
    }
    
    func loadContactsAfterInstall() {
        ServicePlanDataService.shared.updateCurrentSubscription()
        StoreKitManager.default.processAllTransactions() // this should run after every login
        sharedUserDataService.fetchUserInfo().done { (_) in
            
        }.catch { (_) in
            
        }
        //TODO:: here need to be changed
        sharedContactDataService.fetchContacts { (contacts, error) in
            if error != nil {
                PMLog.D("\(String(describing: error))")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        }
    }
    
    func clean() {
        UserTempCachedStatus.backup()
        sharedUserDataService.signOut(true)
        userCachedStatus.signOut()
        sharedMessageDataService.launchCleanUpIfNeeded()
    }
    
    func updateSignInButton(usernameText: String, passwordText: String) {
        signInButton.isEnabled = !usernameText.isEmpty && !passwordText.isEmpty
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            if (self.signInButton.alpha != 0.0) {
                self.signInButton.alpha = self.signInButton.isEnabled ? 1.0 : self.buttonDisabledAlpha
            }
        })
    }
    
    // MARK: - Actions
    
    @IBAction func rememberButtonAction(_ sender: UIButton) {
        isRemembered = !isRemembered
        isRemembered = true
    }
    
    @IBAction func signInAction(_ sender: UIButton) {
        dismissKeyboard()
        signIn()
    }
    
    @IBAction func fogorPasswordAction(_ sender: AnyObject) {
        dismissKeyboard();

        //UIApplication.shared.openURL(forgotPasswordURL)
        let alertStr = LocalString._please_use_the_web_application_to_reset_your_password
        let alertController = alertStr.alertController()
        alertController.addOKAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func signUpAction(_ sender: UIButton) {
        dismissKeyboard()
        self.performSegue(withIdentifier: kSignUpKeySegue, sender: self)
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
}

extension SignInViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(_ code: String, pwd : String) {
        NotificationCenter.default.addKeyboardObserver(self)
        self.cachedTwoCode = code
        self.signIn()
    }

    func Cancel2FA() {
        sharedUserDataService.twoFactorStatus = 0
        NotificationCenter.default.addKeyboardObserver(self)
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
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        self.configConstraint(false)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        updateSignInButton(usernameText: "", passwordText: "")
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let changedText = text.replacingCharacters(in: range, with: string)
        
        if textField == usernameTextField {
            updateSignInButton(usernameText: changedText, passwordText: passwordTextField.text!)
        } else if textField == passwordTextField {
            updateSignInButton(usernameText: usernameTextField.text!, passwordText: changedText)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
