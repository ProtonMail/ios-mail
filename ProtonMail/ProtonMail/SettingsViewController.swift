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

class SettingsViewController: ProtonMailViewController {
    typealias CompletionBlock = APIService.CompletionBlock
    
    // MARK: - Private constants
    
    fileprivate let kKeyboardOffsetHeight: CGFloat = 100.0
    fileprivate let kFieldsMarginLeft: CGFloat = 8.0
    fileprivate let kFieldsMarginTop: CGFloat = 50.0
    fileprivate let resetMailboxPasswordMessage = NSLocalizedString("All of your existing encrypted emails will be lost forever, but you will still be able to view your unencrypted emails.\n\nTHIS ACTION CANNOT BE UNDONE!", comment: "Description")
    
    
    // MARK: - Private attributes
    
    fileprivate var activeField: UIView!
    
    
    // MARK: - Constraint Outlets
    
    @IBOutlet var keyboardOffsetHeightConstraint: NSLayoutConstraint!
    
    
    // MARK: - View Outlets
    
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var notificationContainerView: UIView!
    @IBOutlet var loginPasswordContainerView: UIView!
    @IBOutlet var mailboxPasswordContainerView: UIView!
    @IBOutlet var displayNameContainerView: UIView!
    @IBOutlet var signatureContainerView: UIView!
    
    @IBOutlet var recoveryEmailTextField: UITextField!
    @IBOutlet var currentLoginPasswordTextField: UITextField!
    @IBOutlet var newLoginPasswordTextField: UITextField!
    @IBOutlet var confirmNewLoginPasswordTextField: UITextField!
    @IBOutlet var currentMailboxPasswordTextField: UITextField!
    @IBOutlet var newMailboxPasswordTextField: UITextField!
    @IBOutlet weak var confirmNewMailboxPasswordTextField: UITextField!
    @IBOutlet var displayNameTextField: UITextField!
    @IBOutlet var signatureTextView: UITextView!
    
    @IBOutlet var storageProgressBar: UIProgressView!
    @IBOutlet var storageUsageDescriptionLabel: UILabel!
    
    
    // MARK: - ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        includeBorderOnView(notificationContainerView)
        includeBorderOnView(loginPasswordContainerView)
        includeBorderOnView(mailboxPasswordContainerView)
        includeBorderOnView(displayNameContainerView)
        includeBorderOnView(signatureContainerView)
        includeBorderOnView(signatureTextView)
        
        storageProgressBar.layer.cornerRadius = 5.0
        storageProgressBar.layer.masksToBounds = true
        storageProgressBar.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        setupUserInfo()
    }
    
    @objc func dismissKeyboard() {
        if (self.activeField != nil) {
            self.activeField.resignFirstResponder()
        }
    }
    
    
    // MARK: - Actions Outlets
    
//    @IBAction func recoveryEmailSaveButtonTapped(sender: UIButton) {
//        dismissKeyboard()
//        ActivityIndicatorHelper.showActivityIndicatorAtView(view)
//        
//        sharedUserDataService.updateNotificationEmail(recoveryEmailTextField.text) { _, error in
//            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
//            
//            if let error = error {
//                let alertController = error.alertController()
//                alertController.addOKAction()
//                
//                self.presentViewController(alertController, animated: true, completion: nil)
//            } else {
//                let alertController = UIAlertController(title: NSLocalizedString("Recovery Email Updated"), message: NSLocalizedString("Recovery emails will now be sent to \(self.recoveryEmailTextField.text)."), preferredStyle: .Alert)
//                alertController.addOKAction()
//                
//                self.presentViewController(alertController, animated: true, completion: nil)
//            }
//        }
//    }
    
    @IBAction func loginPasswordSaveButtonTapped(_ sender: UIButton) {
        updatePassword()
    }
    
    @IBAction func mailboxSaveButtonTapped(_ sender: UIButton) {
        updateMailboxPassword()
    }
    
    @IBAction func displayNameSaveButtonTapped(_ sender: UIButton) {
        dismissKeyboard()
        ActivityIndicatorHelper.showActivityIndicator(at: view)
        
        sharedUserDataService.updateDisplayName(displayNameTextField.text!) { _, _, error in
            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
            
            if let error = error {
                let alertController = error.alertController()
                alertController.addOKAction()
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Display Name Updated", comment: "Title"),
                                                        message: String(format: NSLocalizedString("The display name is now %@.", comment: "Description"), "\(String(describing: self.displayNameTextField.text))"),
                                                        preferredStyle: .alert)
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func signatureSaveButtonTapped(_ sender: UIButton) {
        dismissKeyboard()
        ActivityIndicatorHelper.showActivityIndicator(at: view)
        
        sharedUserDataService.updateSignature(signatureTextView.text) { _, _, error in
            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
            
            if let error = error {
                let alertController = error.alertController()
                alertController.addOKAction()
                
                self.present(alertController, animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Signature Updated", comment: "Title"), message: NSLocalizedString("Your signature has been updated.", comment: "Description"), preferredStyle: .alert)
                alertController.addOKAction()
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: - Private methods
    
    fileprivate func clearMailboxPasswordFields() {
        self.currentMailboxPasswordTextField.text = ""
        self.newMailboxPasswordTextField.text = ""
        self.confirmNewMailboxPasswordTextField.text = ""
    }
    
    fileprivate func updateMailboxPassword() {
//        if !sharedUserDataService.isMailboxPasswordValid(currentMailboxPasswordTextField.text, privateKey: sharedUserDataService.userInfo?.privateKey ?? "") {
//            let alertController = UIAlertController(title: NSLocalizedString("Password Mismatch", "Error"), message: NSLocalizedString("The mailbox password you entered does not match the current mailbox password."), preferredStyle: .Alert)
//            alertController.addOKAction()
//            
//            presentViewController(alertController, animated: true, completion: { () -> Void in
//                self.currentMailboxPasswordTextField.text = ""
//            })
//            
//            return
//        }
//        if validatePasswordTextField(newMailboxPasswordTextField, matchesConfirmPasswordTextField: confirmNewMailboxPasswordTextField) {
//            let alertController = UIAlertController(title: NSLocalizedString("Confirm mailbox password change"), message: resetMailboxPasswordMessage, preferredStyle: .ActionSheet)
//            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .Cancel, handler: { (action) -> Void in
//                self.clearMailboxPasswordFields()
//            }))
//            alertController.addAction(UIAlertAction(title: LocalString.change_mailbox_password, style: .Destructive, handler: { (action) -> Void in
//                ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
//                
//                sharedUserDataService.updateMailboxPassword(self.currentMailboxPasswordTextField.text, newMailboxPassword: self.newMailboxPasswordTextField.text) { _, _, error in
//                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
//                    
//                    if let error = error {
//                        let alertController = error.alertController()
//                        alertController.addOKAction()
//                        
//                        self.presentViewController(alertController, animated: true, completion: nil)
//                    } else {
//                        let alertController = UIAlertController(title: NSLocalizedString("Password Updated"), message: NSLocalizedString("Please use your new mailbox password when signing in."), preferredStyle: .Alert)
//                        alertController.addOKAction()
//                        
//                        self.presentViewController(alertController, animated: true, completion: { () -> Void in
//                            self.clearMailboxPasswordFields()
//                        })
//                    }
//                }
//            }))
//        alertController.popoverPresentationController?.sourceView = self.view
//        alertController.popoverPresentationController?.sourceRect = self.view.frame
//            presentViewController(alertController, animated: true, completion: { () -> Void in
//                self.dismissKeyboard()
//            })
//        }
    }
    
    fileprivate func updatePassword() {
        if !sharedUserDataService.isPasswordValid(currentLoginPasswordTextField.text) {
            let alertController = UIAlertController(title: NSLocalizedString("Password Mismatch", comment: "Title"), message: NSLocalizedString("The password you entered does not match the current password.", comment: "Description"), preferredStyle: .alert)
            alertController.addOKAction()
            
            present(alertController, animated: true, completion: { () -> Void in
                self.currentLoginPasswordTextField.text = ""
            })
            
            return
        }
        
        if validatePasswordTextField(newLoginPasswordTextField, matchesConfirmPasswordTextField: confirmNewLoginPasswordTextField) {
            dismissKeyboard()
            
            ActivityIndicatorHelper.showActivityIndicator(at: view)
            
            sharedUserDataService.updatePassword(currentLoginPasswordTextField.text!, new_password: newLoginPasswordTextField.text!, twoFACode: "123456") { _, _, error in
                ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                
                if let error = error {
                    let alertController = error.alertController()
                    alertController.addOKAction()
                    
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    
                    
                    let alertController = UIAlertController(title: NSLocalizedString("Password Updated", comment: "Title"), message: NSLocalizedString("Please use your new password when signing in.", comment: "Description"), preferredStyle: .alert)
                    alertController.addOKAction()
                    
                    self.present(alertController, animated: true, completion: { () -> Void in
                        self.currentLoginPasswordTextField.text = ""
                        self.newLoginPasswordTextField.text = ""
                        self.confirmNewLoginPasswordTextField.text = ""
                    })
                }
            }
        }
    }
    
    fileprivate func validatePasswordTextField(_ passwordTextField: UITextField, matchesConfirmPasswordTextField confirmPasswordTextField: UITextField) -> Bool {
        let result = !passwordTextField.text!.isEmpty && passwordTextField.text == confirmPasswordTextField.text
        
        if !result {
            let alertController = UIAlertController(title: NSLocalizedString("Password Mismatch", comment: "Title"), message: NSLocalizedString("The passwords you entered do not match.", comment: "Description"), preferredStyle: .alert)
            alertController.addOKAction()
            
            present(alertController, animated: true, completion: { () -> Void in
                passwordTextField.text = ""
                confirmPasswordTextField.text = ""
            })
        }
        
        return result
    }
    
    fileprivate func setupUserInfo() {
        storageProgressBar.progress = 0.0
        
        recoveryEmailTextField.text = sharedUserDataService.notificationEmail
        displayNameTextField.text = sharedUserDataService.displayName
        signatureTextView.text = sharedUserDataService.signature
        
        let usedSpace = sharedUserDataService.usedSpace
        let maxSpace = sharedUserDataService.maxSpace
        
        let formattedUsedSpace = ByteCountFormatter.string(fromByteCount: Int64(usedSpace), countStyle: ByteCountFormatter.CountStyle.file)
        let formattedMaxSpace = ByteCountFormatter.string(fromByteCount: Int64(maxSpace), countStyle: ByteCountFormatter.CountStyle.file)
        
        let progress: Float = Float(usedSpace) / Float(maxSpace)
        
        storageProgressBar.setProgress(progress, animated: false)
        storageUsageDescriptionLabel.text = "\(formattedUsedSpace)/\(formattedMaxSpace)"
    }
    
    fileprivate func includeBorderOnView(_ view: UIView) {
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.ProtonMail.Gray_E8EBED.cgColor
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField
        let fieldPosition: CGPoint = self.scrollView.convert(CGPoint.zero, from: textField)
        self.scrollView.setContentOffset(CGPoint(x: textField.frame.minX - kFieldsMarginLeft, y: fieldPosition.y - kFieldsMarginTop), animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch(textField) {
        case currentLoginPasswordTextField:
            newLoginPasswordTextField.becomeFirstResponder()
        case newLoginPasswordTextField:
            confirmNewLoginPasswordTextField.becomeFirstResponder()
        case confirmNewLoginPasswordTextField:
            updatePassword()
        case currentMailboxPasswordTextField:
            newMailboxPasswordTextField.becomeFirstResponder()
        case newMailboxPasswordTextField:
            confirmNewMailboxPasswordTextField.becomeFirstResponder()
        case confirmNewMailboxPasswordTextField:
            updateMailboxPassword()
        default:
            textField.resignFirstResponder()
        }
        
        return true
    }
}

extension SettingsViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.activeField = textView
        
        keyboardOffsetHeightConstraint.constant = kKeyboardOffsetHeight
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
            self.scrollView.slideToBottom()
        })
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.activeField = nil
        keyboardOffsetHeightConstraint.constant = 0.0
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
            self.scrollView.slideToBottom()
        })
    }
}
