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
import MBProgressHUD

class MailboxPasswordViewController: UIViewController {
    let animationDuration: TimeInterval = 0.5
    let buttonDisabledAlpha: CGFloat = 0.5
    let keyboardPadding: CGFloat = 12
    
    @IBOutlet weak var keyboardPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var backgroundImage: UIImageView!

    @IBOutlet weak var passwordManagerButton: UIButton!
    var isRemembered: Bool = sharedUserDataService.isRememberMailboxPassword
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
        passwordTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("MAILBOX PASSWORD", comment: "Title"), attributes:[NSAttributedStringKey.foregroundColor : UIColor(hexColorCode: "#cecaca")])
        
        topTitleLabel.text = NSLocalizedString("DECRYPT MAILBOX", comment: "Title")
        decryptButton.setTitle(NSLocalizedString("Decrypt", comment: "Action"), for: .normal)
        resetMailboxPasswordAction.setTitle(NSLocalizedString("RESET MAILBOX PASSWORD", comment: "Action"), for: .normal)
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
    
    override func didMove(toParentViewController parent: UIViewController?) {
        if (parent == nil) {
            SignInViewController.isComeBackFromMailbox = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func segueForUnwinding(to toViewController: UIViewController, from fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        navigationController?.setNavigationBarHidden(true, animated: true)
        return super.segueForUnwinding(to: toViewController, from: fromViewController, identifier: identifier)!
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
            if loginDictionary == nil {
                if (error as NSError?)?.code != Int(AppExtensionErrorCodeCancelledByUser) {
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
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: navigationBarTitleFont
        ]
    }
    
    func decryptPassword() {
        isRemembered = true
        let password = (passwordTextField.text ?? "") //.trim()
        var mailbox_password = password
        if let keysalt = AuthCredential.getKeySalt(), !keysalt.isEmpty {
            let keysalt_byte : Data = keysalt.decodeBase64()
            mailbox_password = PasswordUtils.getMailboxPassword(password, salt: keysalt_byte)
        }
        if sharedUserDataService.isMailboxPasswordValid(mailbox_password, privateKey: AuthCredential.getPrivateKey()) {
            if sharedUserDataService.isSet {
                sharedUserDataService.setMailboxPassword(mailbox_password, keysalt: nil, isRemembered: self.isRemembered)
                (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
            } else {
                do {
                    try AuthCredential.setupToken(mailbox_password, isRememberMailbox: self.isRemembered)
                    MBProgressHUD.showAdded(to: view, animated: true)
                    sharedLabelsDataService.fetchLabels()
                    sharedUserDataService.fetchUserInfo().done(on: .main) { info in
                        MBProgressHUD.hide(for: self.view, animated: true)
                        if info != nil {
                            if info!.delinquent < 3 {
                                userCachedStatus.pinFailedCount = 0;
                                sharedUserDataService.setMailboxPassword(mailbox_password, keysalt: nil, isRemembered: self.isRemembered)
                                self.restoreBackup()
                                self.loadContent()
                                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationDefined.didSignIn), object: self)
                            } else {
                                let alertController = NSLocalizedString("Access to this account is disabled due to non-payment. Please sign in through protonmail.com to pay your unpaid invoice.", comment: "error message when acction disabled").alertController() //here needs change to a clickable link
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
                    let message = (ex.userInfo["MONExceptionReason"] as? String) ?? NSLocalizedString("The mailbox password is incorrect.", comment: "Error")
                    let alertController = UIAlertController(title: NSLocalizedString("Incorrect password", comment: "Title"), message: NSLocalizedString(message, comment: ""), preferredStyle: .alert)
                    alertController.addOKAction()
                    present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Incorrect password", comment: "Title"), message: NSLocalizedString("The mailbox password is incorrect.", comment: "Error"), preferredStyle: .alert)
            alert.addAction((UIAlertAction.okAction()))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func restoreBackup () {
        UserTempCachedStatus.restore()
    }
    
    fileprivate func loadContent() {
        self.loadContactsAfterInstall()
        (UIApplication.shared.delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
    }
    
    func loadContactsAfterInstall() {
        sharedContactDataService.fetchContacts { (contacts, error) in
            if error != nil {
                PMLog.D("\(String(describing: error))")
            } else {
                PMLog.D("Contacts count: \(contacts!.count)")
            }
        }
    }
    
    func updateButton(_ button: UIButton) {
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            button.alpha = button.isEnabled ? 1.0 : self.buttonDisabledAlpha
        })
    }
    
    
    // MARK: - Actions
    @IBAction func resetMBPAction(_ sender: AnyObject) {
        let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Title"), message: NSLocalizedString("To reset your mailbox password, please use the web version of ProtonMail at protonmail.com", comment: "Description"), preferredStyle: .alert)
        alert.addAction((UIAlertAction.okAction()))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func decryptAction(_ sender: UIButton) {
        decryptPassword()
    }
    
    @IBAction func rememberButtonAction(_ sender: UIButton) {
        self.isRemembered = !isRemembered
        self.isRemembered = true;
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
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
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
