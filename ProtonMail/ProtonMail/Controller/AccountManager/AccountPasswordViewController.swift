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

class AccountPasswordViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
    private var viewModel : SignInViewModel!
    private var coordinator : AccountPasswordCoordinator?
    
    func set(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }
    func set(coordinator: AccountPasswordCoordinator) {
        self.coordinator = coordinator
    }
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    private let animationDuration: TimeInterval = 0.5
    private let keyboardPadding: CGFloat        = 12
    private let buttonDisabledAlpha: CGFloat    = 0.5
    
    private let kDecryptMailboxSegue            = "mailboxSegue"
    private let kSignUpKeySegue                 = "sign_in_to_sign_up_segue"
    private let kSegueTo2FACodeSegue            = "2fa_code_segue"
    
    private var isShowpwd      = false
    
    //define
    private let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0)
    private let showPriority: UILayoutPriority  = UILayoutPriority(rawValue: 750.0)
    
    //views
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signInTitle: UILabel!
    @IBOutlet weak var forgotPwdButton: UIButton!
    
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

        setupTextFields()
        setupButtons()
    }
    
    @objc internal func dismiss() {
        self.navigationController?.popToRootViewController(animated: true)
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
        
    override func didMove(toParent parent: UIViewController?) {
        
//        if (!(parent?.isEqual(self.parent) ?? false)) {
//        }
//
//        if SignInViewController.isComeBackFromMailbox {
//            showLoginViews()
//            SignInManager.shared.clean()
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
        let pwd = (passwordTextField.text ?? "")
        
        updateSignInButton(passwordText: pwd)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueTo2FACodeSegue {
            let popup = segue.destination as! TwoFACodeViewController
            popup.delegate = self
            popup.mode = .twoFactorCode
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        }
    }
    
    // MARK: - Private methods
    
    func dismissKeyboard() {
        passwordTextField.resignFirstResponder()
    }
    
    internal func setupTextFields() {
        signInTitle.text = LocalString._enter_your_mailbox_password
        passwordTextField.attributedPlaceholder = NSAttributedString(string: LocalString._password,
                                                                     attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#cecaca")])
    }
    
    func setupButtons() {
        signInButton.layer.borderColor      = UIColor.ProtonMail.Login_Button_Border_Color.cgColor
        signInButton.alpha                  = buttonDisabledAlpha
        
        signInButton.setTitle(LocalString._decrypt, for: .normal)
        forgotPwdButton.setTitle(LocalString._forgot_password, for: .normal)        
    }
    
    func updateSignInButton(passwordText: String) {
        signInButton.isEnabled = !passwordText.isEmpty
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            if self.signInButton.alpha != 0.0 {
                self.signInButton.alpha = self.signInButton.isEnabled ? 1.0 : self.buttonDisabledAlpha
            }
        })
    }
    
    // MARK: - Actions
    @IBAction func signInAction(_ sender: UIButton) {
        dismissKeyboard()

        self.tryDecrypt()
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
    
    func tryDecrypt() {
        let signInManager = sharedServices.get(by: SignInManager.self)
        let unlockManager = sharedServices.get(by: UnlockManager.self)
        guard let auth = sharedServices.get(by: UsersManager.self).users.last?.auth else {
            unlockManager.delegate?.cleanAll()
            return
        }
        
        let password = (passwordTextField.text ?? "")
        let mailbox_password = signInManager.mailboxPassword(from: password, auth: auth)
        
        MBProgressHUD.showAdded(to: view, animated: true)
        signInManager.proceedWithMailboxPassword(mailbox_password,
                                                 auth: auth,
                                                 onError: { error in
                                    MBProgressHUD.hide(for: self.view, animated: true)
                                    let alert = error.alertController()
                                    alert.addAction((UIAlertAction.okAction()))
                                    self.present(alert, animated: true, completion: nil)
        }, tryUnlock: {
            unlockManager.unlockIfRememberedCredentials(requestMailboxPassword: {})
//            self.dismiss()
        })
    }
    
    func generateToken() -> Promise<String> {
        if #available(iOS 11.0, *) {
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
        }
        
        #if Enterprise
        return Promise<String>.value("EnterpriseBuildInternalTestOnly".encodeBase64())
        #else
        return Promise<String>.init(error: TokenError.unsupport)
        #endif
    }
    
    @IBAction func signUpAction(_ sender: UIButton) {
        dismissKeyboard()
        firstly {
            generateToken()
        }.done { (token) in
            self.performSegue(withIdentifier: self.kSignUpKeySegue, sender: token)
        }.catch { (error) in
            let alert = LocalString._mobile_signups_are_disabled_pls_later_pm_com.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    
    internal func signIn(username: String, password: String, cachedTwoCode: String?) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        SignInViewController.isComeBackFromMailbox = false
        self.viewModel.signIn(username: username, password: password, cachedTwoCode: cachedTwoCode) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)
            switch result {
            case .ask2fa:
                self.performSegue(withIdentifier: self.kSegueTo2FACodeSegue, sender: self)
            case .error(let error):
                PMLog.D("error: \(error)")
                if !error.code.forceUpgrade {
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    self.present(alertController, animated: true, completion: nil)
                }
            case .ok:
                self.dismiss()
            case .mbpwd:
                self.performSegue(withIdentifier: self.kDecryptMailboxSegue, sender: self)
            case .exist:
                let alertController = "The user already logged in".alertController()
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

extension AccountPasswordViewController : TwoFACodeViewControllerDelegate {
    func ConfirmedCode(_ code: String, pwd : String) {
        NotificationCenter.default.addKeyboardObserver(self)
        self.tryDecrypt()
    }

    func Cancel2FA() {
        //TODO:: fix me
//        sharedUserDataService.twoFactorStatus = 0
//        sharedUserDataService.authResponse = nil
        NotificationCenter.default.addKeyboardObserver(self)
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension AccountPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
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
extension AccountPasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        updateSignInButton(passwordText: "")
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let changedText = text.replacingCharacters(in: range, with: string)
        
        if textField == passwordTextField {
            updateSignInButton(passwordText: changedText)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        let pwd = (passwordTextField.text ?? "")
        
        if !pwd.isEmpty {
            
            
            self.tryDecrypt()
            
        }
        
        return true
    }
}
