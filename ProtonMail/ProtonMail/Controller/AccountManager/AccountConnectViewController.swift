//
//  SignInViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import MBProgressHUD
import DeviceCheck
import PromiseKit

class AccountConnectViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
    private var viewModel : SignInViewModel!
    private var coordinator : AccountConnectCoordinator?
    
    func set(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }
    func set(coordinator: AccountConnectCoordinator) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    private let animationDuration: TimeInterval = 0.5
    private let buttonDisabledAlpha: CGFloat    = 0.5
    private var isShowpwd      = false
    private var twoFAFailed = false
    
    //define
    private let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0)
    private let showPriority: UILayoutPriority  = UILayoutPriority(rawValue: 750.0)
    
    //views
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: TextInsetTextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInTitle: UILabel!
    @IBOutlet weak var forgotPwdButton: UIButton!
    @IBOutlet weak var createNewUserButton: UIButton!
    
    // Constraints
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginMidlineConstraint: NSLayoutConstraint!
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LocalString._connect_account
        
        let cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button, style: .plain, target: self, action: #selector(cancelAction))
        self.navigationItem.leftBarButtonItem = cancelButton
        self.navigationItem.assignNavItemIndentifiers()

        setupTextFields()
        setupButtons()
        
        if self.viewModel.username == nil {
            self.showCreateNewAccountButton()
        }
        generateAccessibilityIdentifiers()
    }
    
    @objc internal func dismiss() {
        self.coordinator?.stop()
    }
    
    @objc func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss()
    }

    override var shouldAutorotate : Bool {
        return false
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
    
    func showCreateNewAccountButton() {
        self.createNewUserButton.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        NotificationCenter.default.addKeyboardObserver(self)
        
        let uName = (usernameTextField.text ?? "").trim()
        let pwd = (passwordTextField.text ?? "")
        
        updateSignInButton(usernameText: uName, passwordText: pwd)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UIDevice.current.isLargeScreen() {
            if self.usernameTextField.text?.isEmpty != false {
                usernameTextField.becomeFirstResponder()
            } else if self.passwordTextField.text?.isEmpty != false {
                _ = passwordTextField.becomeFirstResponder()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: - Private methods
    
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    internal func setupTextFields() {
        signInTitle.text = LocalString._login_to_pm_act
        usernameTextField.text = self.viewModel.username
        usernameTextField.attributedPlaceholder = NSAttributedString(string: LocalString._username,
                                                                     attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#cecaca")])
        passwordTextField.attributedPlaceholder = NSAttributedString(string: LocalString._password,
                                                                     attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#cecaca")])
    }
    
    func setupButtons() {
        signInButton.layer.borderColor      = UIColor.ProtonMail.Login_Button_Border_Color.cgColor
        signInButton.alpha                  = buttonDisabledAlpha
        
        signInButton.setTitle(LocalString._general_login, for: .normal)
        forgotPwdButton.setTitle(LocalString._forgot_password, for: .normal)
        createNewUserButton.setTitle(LocalString._create_new_account, for: .normal)
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
    
    enum TokenError : Error {
        case unsupport
        case empty
        case error
    }
    
    func generateToken() -> Promise<String> {
        let currentDevice = DCDevice.current
        if currentDevice.isSupported {
            let deferred = Promise<String>.pending()
            currentDevice.generateToken(completionHandler: { (data, error) in
                if let tokenData = data {
                    deferred.resolver.fulfill(tokenData.base64EncodedString())
                } else if let error = error {
                    deferred.resolver.reject(error)
                } else {
                    deferred.resolver.reject(TokenError.empty)
                }
            })
            return deferred.promise
        }
        
        #if Enterprise
        return Promise<String>.value("EnterpriseBuildInternalTestOnly".encodeBase64())
        #else
        return Promise<String>.init(error: TokenError.unsupport)
        #endif
    }
    
    func showAlert() {
        let alertController = UIAlertController(title: LocalString._free_account_limit_reached_title, message: LocalString._free_account_limit_reached, preferredStyle: .alert)
        alertController.addOKAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func signUpAction(_ sender: UIButton) {
        //check free account
        let count = self.viewModel.usersManager.freeAccountNum()
        if count >= 1 {
            return showAlert()
        }
        self.createNewUserButton.isEnabled = false
        dismissKeyboard()
        firstly {
            self.viewModel.generateToken()
        }.done { (token) in
            self.performSegue(withIdentifier: AccountConnectCoordinator.Destination.signUp.rawValue, sender: token)
        }.catch { (error) in
            let alert = LocalString._mobile_signups_are_disabled_pls_later_pm_com.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }.finally {
            self.createNewUserButton.isEnabled = true
        }
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    internal func signIn(username: String, password: String, cachedTwoCode: String?) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        SignInViewController.isComeBackFromMailbox = false
        self.viewModel.signIn(username: username, password: password, cachedTwoCode: cachedTwoCode, faillogout: false) { (result) in
            switch result {
            case .ask2fa:
                MBProgressHUD.hide(for: self.view, animated: true)
                self.coordinator?.go(to: .twoFACode, sender: self)
            case .error(let error):
                PMLog.D("error: \(error)")
                MBProgressHUD.hide(for: self.view, animated: true)
                guard cachedTwoCode != nil else {
                    self.handleRequestError(error)
                    return
                }
                if self.twoFAFailed {
                    self.twoFAFailed = false
                    self.coordinator?.go(to: .twoFACode, sender: self)
                } else {
                    self.twoFAFailed = true
                    self.signIn(username: username, password: password, cachedTwoCode: cachedTwoCode)
                }
            case .ok:
                MBProgressHUD.hide(for: self.view, animated: true)
                self.dismiss()
            case .mbpwd:
                self.coordinator?.go(to: .decryptMailbox, sender: self)
            case .exist:
                MBProgressHUD.hide(for: self.view, animated: true)
                let alertController = LocalString._duplicate_logged_in.alertController()
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
            case .limit:
                MBProgressHUD.hide(for: self.view, animated: true)
                self.showAlert()
            }
        }
    }
    
    func handleRequestError (_ error : NSError) {
        let code = error.code
//        if DoHMail.default.status != .off {
//            let alertController = error.alertController()
//            alertController.addOKAction()
//            self.present(alertController, animated: true, completion: nil)
//        }
//        else if code == NSURLErrorNotConnectedToInternet || code == NSURLErrorCannotConnectToHost {
//            let alertController = error.alertController()
//            alertController.addOKAction()
//            self.present(alertController, animated: true, completion: nil)
//        }
//        else
        if !self.checkDoh(error) && !code.forceUpgrade {
            let alertController = error.alertController()
            alertController.addOKAction()
            self.present(alertController, animated: true, completion: nil)
        }
        PMLog.D("error: \(error)")
    }
    private func checkDoh(_ error : NSError) -> Bool {
        let code = error.code
        guard DoHMail.default.codeCheck(code: code) else {
            return false
        }
        
        //TODO:: don't use FailureReason in the future. also need clean up
        let message = error.localizedFailureReason ?? error.localizedDescription
        let alertController = UIAlertController(title: LocalString._protonmail,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Troubleshoot", style: .default, handler: { action in
            self.coordinator?.go(to: .troubleShoot)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: { action in
            
        }))
        
//        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        
        self.present(alertController, animated: true, completion: nil)

        return true
    }
}

extension AccountConnectViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(_ code: String, pwd : String) {
        NotificationCenter.default.addKeyboardObserver(self)
        self.signIn(username: usernameTextField.text ?? "",
                    password: passwordTextField.text ?? "",
                    cachedTwoCode: code)
    }

    func Cancel2FA() {
        UserDataService.authResponse = nil
        NotificationCenter.default.addKeyboardObserver(self)
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension AccountConnectViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
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
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension AccountConnectViewController: UITextFieldDelegate {
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
            _ = passwordTextField.becomeFirstResponder()
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
