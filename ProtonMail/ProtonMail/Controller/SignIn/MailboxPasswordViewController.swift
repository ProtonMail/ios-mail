//
//  MailboxPasswordViewController.swift
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


import Foundation
import MBProgressHUD

class MailboxPasswordViewController: UIViewController, AccessibleView {
    let animationDuration: TimeInterval = 0.5
    let buttonDisabledAlpha: CGFloat = 0.5
    let keyboardPadding: CGFloat = 12
    
    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var backgroundImage: UIImageView!

    @IBOutlet weak var passwordManagerButton: UIButton!
    var isShowpwd : Bool = false;
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority = UILayoutPriority(rawValue: 750.0);
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var decryptWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var decryptMidConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var decryptButton: UIButton!
    @IBOutlet weak var resetMailboxPasswordAction: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDecryptButton()
        passwordTextField.attributedPlaceholder = NSAttributedString(string: LocalString._mailbox_password, attributes:[NSAttributedString.Key.foregroundColor : UIColor(hexColorCode: "#cecaca")])
        
        topTitleLabel.text = LocalString._decrypt_mailbox
        decryptButton.setTitle(LocalString._decrypt, for: .normal)
        resetMailboxPasswordAction.setTitle(LocalString._reset_mailbox_password, for: .normal)
        generateAccessibilityIdentifiers()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
    
    func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        passwordTopPaddingConstraint.priority = level
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
        
        if OnePasswordExtension.shared().isAppExtensionAvailable() == true {
            passwordManagerButton.isHidden = false
            decryptWidthConstraint.constant = 120
            decryptMidConstraint.constant = -72
        } else {
            passwordManagerButton.isHidden = true
            decryptWidthConstraint.constant = 200
            decryptMidConstraint.constant = 0
        }
        
        if let pwdTxt = passwordTextField.text {
            decryptButton.isEnabled = !pwdTxt.isEmpty
            updateButton(decryptButton)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if(UIDevice.current.isLargeScreen())
        {
            passwordTextField.becomeFirstResponder()
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if (parent == nil) {
            SignInViewController.isComeBackFromMailbox = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    func setupDecryptButton() {
        decryptButton.layer.borderColor = UIColor.ProtonMail.Login_Button_Border_Color.cgColor;
        decryptButton.alpha = buttonDisabledAlpha
        
        passwordManagerButton.layer.borderColor = UIColor.white.cgColor
        passwordManagerButton.layer.borderWidth = 2
    }
    
    
    // MARK: - private methods
    @IBAction func onePasswordAction(_ sender: UIButton) {
        OnePasswordExtension.shared().findLogin(forURLString: "https://protonmail.com", for: self, sender: sender, completion: { (loginDictionary, error) -> Void in
            let cancelError: AppExtensionErrorCode = .cancelledByUser
            if loginDictionary == nil {
                if (error as NSError?)?.code != Int(cancelError.rawValue) {
                    PMLog.D("Error invoking Password App Extension for find login: \(String(describing: error))")
                }
                return
            }
            let password : String! = (loginDictionary?[AppExtensionPasswordKey] as? String ?? "")
            self.passwordTextField.text = password
            if !password.isEmpty {
                self.decryptButton.isEnabled = !password.isEmpty
                self.updateButton(self.decryptButton)
                self.decryptPassword()
            }
        })
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = Fonts.h2.light
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
    }
    
    func decryptPassword() {
        let signInManager = sharedServices.get(by: SignInManager.self)
        let unlockManager = sharedServices.get(by: UnlockManager.self)
        guard let auth = signInManager.auth else {
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
        }, reachLimit: {}, existError: {}, tryUnlock: {
            unlockManager.unlockIfRememberedCredentials(requestMailboxPassword: {})
        })
    }
    
    func updateButton(_ button: UIButton) {
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            button.alpha = button.isEnabled ? 1.0 : self.buttonDisabledAlpha
        })
    }
    
    
    // MARK: - Actions
    @IBAction func resetMBPAction(_ sender: AnyObject) {
        let alert = UIAlertController(title: LocalString._general_alert_title,
                                      message: LocalString._to_reset_your_mailbox_password_please_use_the_web_version_of_protonmail,
                                      preferredStyle: .alert)
        alert.addAction((UIAlertAction.okAction()))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func decryptAction(_ sender: UIButton) {
        decryptPassword()
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        passwordTextField.resignFirstResponder()
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        let _ = navigationController?.popViewController(animated: true);
    }
    @IBAction func showAction(_ sender: UIButton) {
        self.isShowpwd = !isShowpwd
        sender.isSelected = isShowpwd
        
        if isShowpwd {
            self.passwordTextField.isSecureTextEntry = false;
        } else {
            self.passwordTextField.isSecureTextEntry = true;
        }
        
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension MailboxPasswordViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        configConstraint(false)
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
        configConstraint(true)
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}


// MARK: - UITextFieldDelegate

extension MailboxPasswordViewController: UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        decryptButton.isEnabled = false
        updateButton(decryptButton)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text as NSString? {
            let changedText = text.replacingCharacters(in: range, with: string)
            if textField == passwordTextField {
                decryptButton.isEnabled = !(changedText.isEmpty)
            }
            updateButton(decryptButton)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let pwd = (passwordTextField.text ?? "") //.trim()
        if !pwd.isEmpty {
            decryptPassword()
        }
        return true
    }
}
