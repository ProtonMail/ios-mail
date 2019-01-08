//
//  SignInViewController.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import MBProgressHUD

class SignInViewController: ProtonMailViewController {
    static var isComeBackFromMailbox = false
    
    private let animationDuration: TimeInterval = 0.5
    private let keyboardPadding: CGFloat        = 12
    private let buttonDisabledAlpha: CGFloat    = 0.5
    
    private let kDecryptMailboxSegue            = "mailboxSegue"
    private let kSignUpKeySegue                 = "sign_in_to_sign_up_segue"
    private let kSegueToSignUpWithNoAnimation   = "sign_in_to_splash_no_segue"
    private let kSegueToPinCodeViewNoAnimation  = "pin_code_segue"
    private let kSegueTo2FACodeSegue            = "2fa_code_segue"
    
    private var isShowpwd      = false
    private var isRemembered   = false
    private var showingTouchID = false
    
    //define
    private let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0)
    private let showPriority: UILayoutPriority  = UILayoutPriority(rawValue: 750.0)
    
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

        if !showingTouchID {
            showingTouchID = true
            let signinFlow = UnlockManager.shared.getUnlockFlow()
            signinFlow == .requireTouchID ? self.showTouchID(false) : self.hideTouchID(true)
            UnlockManager.shared.initiateUnlock(flow: signinFlow,
                                                requestPin: {
                                                    self.showingTouchID = false
                                                    self.performSegue(withIdentifier: self.kSegueToPinCodeViewNoAnimation, sender: self) },
                                                requestMailboxPassword: {
                                                    self.showingTouchID = false
                                                    self.isRemembered = true
                                                    self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
            })
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
    
    internal func setupVersionLabel () {
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
    
    func setupView() {
        if isRemembered {
            HideLoginViews()
        } else {
            ShowLoginViews()
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
            self.passwordTextField.isSecureTextEntry = false
        } else {
            self.passwordTextField.isSecureTextEntry = true
        }
    }
    
    @IBAction func touchIDAction(_ sender: UIButton) {
        if userCachedStatus.isTouchIDEnabled {
            UnlockManager.shared.biometricAuthentication(requestMailboxPassword: {
                self.isRemembered = true
                self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
            })
        } else {
            hideTouchID()
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if (!(parent?.isEqual(self.parent) ?? false)) {
        }
        
        if SignInViewController.isComeBackFromMailbox {
            ShowLoginViews()
            SignInManager.shared.clean()
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
            
            let username : String = (loginDictionary?[AppExtensionUsernameKey] as? String ?? "").trim()
            let password : String = (loginDictionary?[AppExtensionPasswordKey] as? String ?? "")
            
            self.usernameTextField.text = username
            self.passwordTextField.text = password
            
            if !username.isEmpty && !password.isEmpty {
                self.updateSignInButton(usernameText: username, passwordText: password)
                self.signIn(username: self.usernameTextField.text ?? "",
                            password: self.passwordTextField.text ?? "",
                            cachedTwoCode: nil) // FIXME
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showingTouchID = false
        navigationController?.setNavigationBarHidden(true, animated: true)
        NotificationCenter.default.addKeyboardObserver(self)
        NotificationCenter.default.addObserver(self, selector:#selector(SignInViewController.doEnterForeground),
                                               name:  UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(SignInViewController.doEnterBackground),
                                               name:  UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        let uName = (usernameTextField.text ?? "").trim()
        let pwd = (passwordTextField.text ?? "")
        
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
        if userCachedStatus.isTouchIDEnabled && !showingTouchID {
            showingTouchID = true
            //TODO::fixme. need to add a callback event when touch id/face id canceled or dismissed. `workaround is func doEnterBackground()`
            UnlockManager.shared.biometricAuthentication(requestMailboxPassword: {
                self.showingTouchID = false
                self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
            })
        }
    }
    
    @objc func doEnterBackground() {
        self.showingTouchID = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if sharedUserDataService.isNewUser {
            sharedUserDataService.isNewUser = false
            if sharedUserDataService.isUserCredentialStored {
                UnlockManager.shared.unlockIfRememberedCredentials(requestMailboxPassword: {
                    self.isRemembered = true
                    self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
                })
                if isRemembered {
                    HideLoginViews()
                } else {
                    ShowLoginViews()
                }
            }
        }
        
        if SignInViewController.isComeBackFromMailbox {
            ShowLoginViews()
            SignInManager.shared.clean()
        }
        
        if UIDevice.current.isLargeScreen() && !isRemembered {
            let signinFlow = UnlockManager.shared.getUnlockFlow()
            if signinFlow != .requireTouchID {
                usernameTextField.becomeFirstResponder()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
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
    
    internal func HideLoginViews() {
        self.usernameView.alpha      = 0.0
        self.passwordView.alpha      = 0.0
        self.signInButton.alpha      = 0.0
        self.onePasswordButton.alpha = 0.0
    }
    
    func ShowLoginViews() {
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
        signInButton.layer.borderColor      = UIColor.ProtonMail.Login_Button_Border_Color.cgColor
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
    
    func updateSignInButton(usernameText: String, passwordText: String) {
        signInButton.isEnabled = !usernameText.isEmpty && !passwordText.isEmpty
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            if self.signInButton.alpha != 0.0 {
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
        self.signIn(username: self.usernameTextField.text ?? "",
                    password: self.passwordTextField.text ?? "",
                    cachedTwoCode: nil) // FIXME
    }
    
    @IBAction func fogorPasswordAction(_ sender: AnyObject) {
        dismissKeyboard()

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
    
    internal func signIn(username: String,
                         password: String,
                         cachedTwoCode: String?)
    {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        self.isRemembered = true
        SignInViewController.isComeBackFromMailbox = false
        
        SignInManager.shared.signIn(username: username,
                        password: password,
                        cachedTwoCode: cachedTwoCode,
                        ask2fa: {
                            //2fa
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.performSegue(withIdentifier: self.kSegueTo2FACodeSegue, sender: self)
        },
                        onError: { error in
                            PMLog.D("error: \(error)")
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.ShowLoginViews()
                            if !error.code.forceUpgrade {
                                let alertController = error.alertController()
                                alertController.addOKAction()
                                self.present(alertController, animated: true, completion: nil)
                            }
        },
                        afterSignIn: {
                            MBProgressHUD.hide(for: self.view, animated: true)
        },
                        requestMailboxPassword: {
                            self.isRemembered = true
                            self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
        })
    }
}

extension SignInViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(_ code: String, pwd : String) {
        NotificationCenter.default.addKeyboardObserver(self)
        self.signIn(username: self.usernameTextField.text ?? "",
                    password: self.passwordTextField.text ?? "",
                    cachedTwoCode: code)
    }

    func Cancel2FA() {
        sharedUserDataService.twoFactorStatus = 0
        NotificationCenter.default.addKeyboardObserver(self)
    }
}

extension SignInViewController : PinCodeViewControllerDelegate {
    
    func Cancel() {
        UserTempCachedStatus.backup()
        SignInManager.shared.clean()
    }
    
    func Next() {
        UnlockManager.shared.unlockIfRememberedCredentials(requestMailboxPassword: {
            self.isRemembered = true
            self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
        })
        setupView()
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
            scrollBottomPaddingConstraint.constant = keyboardSize.height
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
        let pwd = (passwordTextField.text ?? "")
        
        if !uName.isEmpty && !pwd.isEmpty {
            self.signIn(username: self.usernameTextField.text ?? "",
                        password: self.passwordTextField.text ?? "",
                        cachedTwoCode: nil) // FIXME
        }
        
        return true
    }
}
