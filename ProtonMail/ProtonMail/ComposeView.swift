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

protocol ComposeViewDelegate {
    func composeViewDidTapCancelButton(composeView: ComposeView)
    func composeViewDidTapSendButton(composeView: ComposeView)
    func composeViewDidTapNextButton(composeView: ComposeView)
    func composeViewDidTapEncryptedButton(composeView: ComposeView)
}

protocol ComposeViewDatasource {
    func composeViewContactsModel(composeView: ComposeView) -> [AnyObject]!
    func composeViewSelectedContacts(composeView: ComposeView) -> [AnyObject]!
}

class ComposeView: UIView {

    
    // MARK: - Constants
    
    private let kErrorMessageHeight: CGFloat = 48.0
    
    // MARK: - Delegate and Datasource
    
    var datasource: ComposeViewDatasource?
    var delegate: ComposeViewDelegate?
    
    
    // MARK: - Private atributes
    
    var errorView: UIView!
    var errorTextView: UITextView!
    
    
    // MARK: - View Outlets
    
    @IBOutlet var contactPickerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contactPicker: MBContactPicker!
    @IBOutlet var subject: UITextField!
    @IBOutlet var encryptedButton: UIButton!
    @IBOutlet var expirationButton: UIButton!
    @IBOutlet var attachmentButton: UIButton!
    
    
    // MARK: - Encryption password
    
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var buttonActions: UIView!
    @IBOutlet var actionButton: UIButton!
    @IBOutlet var buttonView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func didTapCancelButton(sender: AnyObject) {
        self.delegate?.composeViewDidTapCancelButton(self)
    }
    
    @IBAction func didTapSendButton(sender: AnyObject) {
        self.delegate?.composeViewDidTapSendButton(self)
    }
    
    @IBAction func didTapEncryptedButton(sender: UIButton) {
        
        self.delegate?.composeViewDidTapEncryptedButton(self)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.encryptedButton.setImage(UIImage(named: "encrypted_compose"), forState: UIControlState.Normal)
            self.buttonActions.alpha = 1.0
            self.buttonView.alpha = 0.0
        })
    }
    
    @IBAction func didTapEncryptedDismissButton(sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.passwordTextField.text = ""
            self.buttonActions.alpha = 0.0
            self.buttonView.alpha = 1.0
        })
    }
    
    internal func showDefinePasswordView() {
        self.passwordTextField.placeholder = NSLocalizedString("Define Password")
        self.passwordTextField.secureTextEntry = true
        self.passwordTextField.text = ""
    }
    
    internal func showConfirmPasswordView() {
        self.passwordTextField.placeholder = NSLocalizedString("Confirm Password")
        self.passwordTextField.secureTextEntry = true
        self.passwordTextField.text = ""
    }
    
    internal func showPasswordHintView() {
        self.passwordTextField.placeholder = NSLocalizedString("Define Hint")
        self.passwordTextField.secureTextEntry = false
        self.passwordTextField.text = ""
    }
    
    internal func showEncryptionDone() {
        didTapEncryptedDismissButton(encryptedButton)
        self.passwordTextField.placeholder = NSLocalizedString("Define Password")
        self.passwordTextField.secureTextEntry = true
        self.encryptedButton.setImage(UIImage(named: "encrypted_compose_checked"), forState: UIControlState.Normal)
    }
    
    internal func showPasswordAndConfirmDoesntMatch() {
        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959
        self.errorView.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.left.equalTo()(self)
            update.right.equalTo()(self)
            update.height.equalTo()(self.kErrorMessageHeight)
            update.top.equalTo()(self.passwordTextField.mas_bottom)
        }
        
        self.errorTextView.shake(3, offset: 10)
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    internal func hidePasswordAndConfirmDoesntMatch() {
        self.errorView.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.left.equalTo()(self)
            update.right.equalTo()(self)
            update.height.equalTo()(0)
            update.top.equalTo()(self.passwordTextField.mas_bottom)
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureContactPicketTemplate()
        self.includeButtonBorder(encryptedButton)
        self.includeButtonBorder(attachmentButton)
        self.includeButtonBorder(passwordTextField)
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        self.subject.addBorder(.Top, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        self.expirationButton.addBorder(.Top, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        self.expirationButton.addBorder(.Bottom, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
        self.contactPicker.datasource = self
        self.contactPicker.delegate = self
        
        let subjectLeftPaddingView = UIView(frame: CGRectMake(0, 0, 12, self.subject.frame.size.height))
        subject.leftView = subjectLeftPaddingView
        subject.leftViewMode = UITextFieldViewMode.Always
        
        self.configurePasswordField()
        self.configureErrorMessage()
    }
    
    // MARK: - Private Methods
    
    private func includeButtonBorder(view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.CGColor
    }
    
    private func updateContactPickerHeight(newHeight: CGFloat) {
        self.contactPickerHeightConstraint.constant = newHeight
        
        UIView.animateWithDuration(NSTimeInterval(contactPicker.animationSpeed), animations: { () -> Void in
            self.layoutIfNeeded()
        })
    }
    
    private func configureContactPicketTemplate() {
        MBContactCollectionViewContactCell.appearance().tintColor = UIColor.ProtonMail.Blue_6789AB
        MBContactCollectionViewContactCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h4)
        MBContactCollectionViewPromptCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h4)
        MBContactCollectionViewEntryCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h4)
    }
    
    private func configurePasswordField() {
        let passwordLeftPaddingView = UIView(frame: CGRectMake(0, 0, 12, self.passwordTextField.frame.size.height))
        passwordTextField.leftView = passwordLeftPaddingView
        passwordTextField.leftViewMode = UITextFieldViewMode.Always
        
        let nextButton = UIButton()
        nextButton.addTarget(self, action: "didTapNextButton", forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.setImage(UIImage(named: "next"), forState: UIControlState.Normal)
        nextButton.sizeToFit()
        
        let nextView = UIView(frame: CGRectMake(0, 0, nextButton.frame.size.width + 10, nextButton.frame.size.height))
        nextView.addSubview(nextButton)
        passwordTextField.rightView = nextView
        passwordTextField.rightViewMode = UITextFieldViewMode.Always
    }
    
    
    internal func didTapNextButton() {
        self.delegate?.composeViewDidTapNextButton(self)
    }
    
    private func configureErrorMessage() {
        self.errorView = UIView()
        self.errorView.backgroundColor = UIColor.whiteColor()
        
        self.errorTextView = UITextView()
        self.errorTextView.backgroundColor = UIColor.clearColor()
        self.errorTextView.font = UIFont.robotoLight(size: UIFont.Size.h4)
        self.errorTextView.text = NSLocalizedString("Message password doesn't match.")
        self.errorTextView.textAlignment = NSTextAlignment.Center
        self.errorTextView.textColor = UIColor.whiteColor()
        self.errorTextView.sizeToFit()
        self.addSubview(errorView)
        errorView.addSubview(errorTextView)
        
        self.errorView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(0)
            make.top.equalTo()(self.passwordTextField.mas_bottom)
        }
        
        errorTextView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self)
            make.right.equalTo()(self)
            make.height.equalTo()(self.errorTextView.frame.size.height)
            make.top.equalTo()(self.errorView).with().offset()(8)
        }
    }
}


// MARK: - MBContactPickerDataSource

extension ComposeView: MBContactPickerDataSource {
    func contactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        return self.datasource?.composeViewContactsModel(self)
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        return self.datasource?.composeViewSelectedContacts(self)
    }
}


// MARK: - MBContactPickerDelegate

extension ComposeView: MBContactPickerDelegate {
    
    func customFilterPredicate(searchString: String!) -> NSPredicate! {
        return NSPredicate(format: "contactTitle CONTAINS[cd] %@ or contactSubtitle CONTAINS[cd] %@", argumentArray: [searchString, searchString])
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didSelectContact model: MBContactPickerModelProtocol!) {
        
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didAddContact model: MBContactPickerModelProtocol!) {
        
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didRemoveContact model: MBContactPickerModelProtocol!) {
        
    }
    
    func didShowFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        if (contactPickerHeightConstraint.constant <= contactPicker.currentContentHeight) {
            let pickerRectInWindow = self.convertRect(contactPicker.frame, fromView: nil)
            let newHeight = self.window!.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight
            self.updateContactPickerHeight(newHeight)
        }
    }
    
    func didHideFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        if (self.contactPickerHeightConstraint.constant > contactPicker.currentContentHeight) {
            self.updateContactPickerHeight(contactPicker.currentContentHeight)
        }
    }
    
    func contactPicker(contactPicker: MBContactPicker!, didUpdateContentHeightTo newHeight: CGFloat) {
        self.updateContactPickerHeight(newHeight)
    }
}
