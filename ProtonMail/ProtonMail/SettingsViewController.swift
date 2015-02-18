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
    
    // MARK: - View Outlets
    
    @IBOutlet var notificationContainerView: UIView!
    @IBOutlet var loginPasswordContainerView: UIView!
    @IBOutlet var mailboxPasswordContainerView: UIView!
    @IBOutlet var displayNameContainerView: UIView!
    @IBOutlet var signatureContainerView: UIView!
    
    @IBOutlet var recoveryEmailTextField: UITextField!
    @IBOutlet var currentLoginPasswordTextField: UITextField!
    @IBOutlet var currentMailboxPasswordTextField: UITextField!
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
        
        setupUserInfo()
    }
    
    
    // MARK: - Actions Outlets
    
    @IBAction func recoveryEmailSaveButtonTapped(sender: UIButton) {
    }
    
    @IBAction func recoveryEmailDeleteButtonTapped(sender: UIButton) {
    }
    
    @IBAction func loginPasswordSaveButtonTapped(sender: UIButton) {
    }
    
    @IBAction func mailboxSaveButtonTapped(sender: UIButton) {
    }
    
    @IBAction func displayNameSaveButtonTapped(sender: UIButton) {
        ActivityIndicatorHelper.showActivityIndicatorAtView(displayNameContainerView)
        
        sharedUserDataService.updateDisplayName(displayNameTextField.text) { error in
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.displayNameContainerView)
        }
    }
    
    @IBAction func signatureSaveButtonTapped(sender: UIButton) {
        ActivityIndicatorHelper.showActivityIndicatorAtView(signatureContainerView)
        
        sharedUserDataService.updateSignature(signatureTextView.text) { error in
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.signatureContainerView)
        }
    }
    
    
    // MARK: - Private methods
    
    private func setupUserInfo() {
        storageProgressBar.progress = 0.0
        
        recoveryEmailTextField.text = sharedUserDataService.notificationEmail
        displayNameTextField.text = sharedUserDataService.displayName
        signatureTextView.text = sharedUserDataService.signature
        
        let usedSpace = sharedUserDataService.usedSpace
        let maxSpace = sharedUserDataService.maxSpace
        
        let formattedUsedSpace = NSByteCountFormatter.stringFromByteCount(Int64(usedSpace), countStyle: NSByteCountFormatterCountStyle.File)
        let formattedMaxSpace = NSByteCountFormatter.stringFromByteCount(Int64(maxSpace), countStyle: NSByteCountFormatterCountStyle.File)
        
        let progress: Float = Float(usedSpace) / Float(maxSpace)
        
        storageProgressBar.setProgress(progress, animated: true)
        storageUsageDescriptionLabel.text = "\(formattedUsedSpace)/\(formattedMaxSpace)"
    }
    
    private func includeBorderOnView(view: UIView) {
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.ProtonMail.Gray_E8EBED.CGColor
    }
}