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
//TODO:: not in used 
class SettingsViewController: ProtonMailViewController {
    typealias CompletionBlock = APIService.CompletionBlock
    
    // MARK: - Private constants
    
    fileprivate let kKeyboardOffsetHeight: CGFloat = 100.0
    fileprivate let kFieldsMarginLeft: CGFloat = 8.0
    fileprivate let kFieldsMarginTop: CGFloat = 50.0
    fileprivate let resetMailboxPasswordMessage = LocalString._all_of_your_existing_encrypted_emails_will_be_lost_forever_but_you_will_still_be_able_to_view_your_unencrypted_emails_
    
    
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
                let alertController = UIAlertController(title: LocalString._display_name_updated,
                                                        message: String(format: LocalString._the_display_name_is_now, "\(String(describing: self.displayNameTextField.text))"),
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
                let alertController = UIAlertController(title: LocalString._signature_updated,
                                                        message: LocalString._your_signature_has_been_updated,
                                                        preferredStyle: .alert)
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

    }
    
    fileprivate func updatePassword() {
        if !sharedUserDataService.isPasswordValid(currentLoginPasswordTextField.text) {
            let alertController = UIAlertController(title: LocalString._password_mismatch,
                                                    message: LocalString._the_password_you_entered_does_not_match_the_current_password,
                                                    preferredStyle: .alert)
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
                    
                    
                    let alertController = UIAlertController(title: LocalString._password_updated,
                                                            message: LocalString._please_use_your_new_password_when_signing_in,
                                                            preferredStyle: .alert)
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
            let alertController = UIAlertController(title: LocalString._password_mismatch,
                                                    message: LocalString._the_passwords_you_entered_do_not_match,
                                                    preferredStyle: .alert)
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
        signatureTextView.text = sharedUserDataService.userDefaultSignature
        
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
