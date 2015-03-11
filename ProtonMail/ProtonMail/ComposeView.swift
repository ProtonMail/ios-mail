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
    func composeViewDidTapAttachmentButton(composeView: ComposeView)
}

protocol ComposeViewDatasource {
    func composeViewContactsModel(composeView: ComposeView) -> [AnyObject]!
    func composeViewSelectedContacts(composeView: ComposeView) -> [AnyObject]!
}

class ComposeView: UIView {

    
    // MARK: - Constants
    
    private let kErrorMessageHeight: CGFloat = 48.0
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int = 30
    private let kNumberOfHoursInTimePicker: Int = 24

    
    // MARK: - Delegate and Datasource
    
    var datasource: ComposeViewDatasource?
    var delegate: ComposeViewDelegate?
    
    
    // MARK: - Private atributes
    
    private var errorView: UIView!
    private var errorTextView: UITextView!
    
    
    // MARK: - View Outlets
    
    @IBOutlet var contactPickerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contactPicker: MBContactPicker!
    @IBOutlet var subject: UITextField!
    @IBOutlet var bodyTextView: UITextView!
    
    
    // MARK: - Action Buttons
    
    @IBOutlet var buttonView: UIView!
    @IBOutlet var encryptedButton: UIButton!
    @IBOutlet var expirationButton: UIButton!
    @IBOutlet var attachmentButton: UIButton!
    
    
    // MARK: - Encryption password
    
    @IBOutlet var passwordView: UIView!
    @IBOutlet var encryptedPasswordTextField: UITextField!
    @IBOutlet var encryptedActionButton: UIButton!

    
    // MARK: - Expiration Date
    
    @IBOutlet var expirationView: UIView!
    @IBOutlet var expirationDateTextField: UITextField!
    @IBOutlet var expirationPicker: UIPickerView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureContactPicketTemplate()
        self.includeButtonBorder(encryptedButton)
        self.includeButtonBorder(attachmentButton)
        self.includeButtonBorder(encryptedPasswordTextField)
        self.includeButtonBorder(expirationDateTextField)
        
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
        
        expirationPicker.alpha = 0.0
        expirationPicker.dataSource = self
        expirationPicker.delegate = self

        self.configureBodyTextField()
        self.configureEncryptionPasswordField()
        self.configureErrorMessage()
        self.configureExpirationField()
       
        self.registerForKeyboardNotifications()
    }
    
    deinit {
        unregisterForKeybardNotifications()
    }
    
    func keyboardWasShown(notification: NSNotification) {
        if (self.bodyTextView != nil) {
            let info: NSDictionary = notification.userInfo!
            let keyboardRect: CGRect = self.bodyTextView.convertRect(info[UIKeyboardFrameEndUserInfoKey]!.CGRectValue(), fromView:nil)
            let keyboardSize: CGSize = keyboardRect.size;
    
            self.bodyTextView.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
            self.bodyTextView.scrollIndicatorInsets = self.bodyTextView.contentInset
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        self.bodyTextView.scrollIndicatorInsets = UIEdgeInsetsZero
        self.bodyTextView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.delegate?.composeViewDidTapCancelButton(self)
    }

    @IBAction func sendButtonTapped(sender: AnyObject) {
        self.delegate?.composeViewDidTapSendButton(self)
    }
    
    @IBAction func encryptedButtonTapped(sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        self.encryptedPasswordTextField.becomeFirstResponder()
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.encryptedButton.setImage(UIImage(named: "encrypted_compose"), forState: UIControlState.Normal)
            self.passwordView.alpha = 1.0
            self.buttonView.alpha = 0.0
        })
    }
    
    @IBAction func didTapEncryptedDismissButton(sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.encryptedPasswordTextField.text = ""
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 1.0
        })
    }
    
    @IBAction func expirationButtonTapped(sender: UIButton) {

        self.expirationButton.setImage(UIImage(named: "expiration_compose"), forState: UIControlState.Normal)
        self.endEditing(true)
        self.expirationDateTextField.becomeFirstResponder()
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 0.0
            self.expirationView.alpha = 1.0
            
            self.contactPicker.userInteractionEnabled = false
            self.subject.userInteractionEnabled = false
            
            self.showExpirationPicker()
        })
    }
    
    @IBAction func attachmentButtonTapped(sender: UIButton) {
        self.endEditing(true)
        self.delegate?.composeViewDidTapAttachmentButton(self)
    }
    
    @IBAction func didTapExpirationDismissButton(sender: UIButton) {
        self.hideExpirationPicker()
    }
    
    internal func didTapConfirmButton() {
        self.expirationButton.setImage(UIImage(named: "expiration_compose_checked"), forState: UIControlState.Normal)
        self.hideExpirationPicker()
    }
    
    internal func showDefinePasswordView() {
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Password")
        self.encryptedPasswordTextField.secureTextEntry = true
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showConfirmPasswordView() {
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Confirm Password")
        self.encryptedPasswordTextField.secureTextEntry = true
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showPasswordHintView() {
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Hint")
        self.encryptedPasswordTextField.secureTextEntry = false
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showEncryptionDone() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Password")
        self.encryptedPasswordTextField.secureTextEntry = true
        self.encryptedButton.setImage(UIImage(named: "encrypted_compose_checked"), forState: UIControlState.Normal)
    }
    
    internal func showExpirationPicker() {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.expirationPicker.alpha = 1.0
        })
    }
    
    internal func hideExpirationPicker() {
        self.contactPicker.userInteractionEnabled = true
        self.subject.userInteractionEnabled = true

        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.expirationView.alpha = 0.0
            self.buttonView.alpha = 1.0
            self.expirationPicker.alpha = 0.0
        })
    }
    
    internal func showPasswordAndConfirmDoesntMatch() {
        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959
        self.errorView.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.left.equalTo()(self)
            update.right.equalTo()(self)
            update.height.equalTo()(self.kErrorMessageHeight)
            update.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
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
            update.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.layoutIfNeeded()
        })
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
    
    private func configureBodyTextField() {

    }
    
    private func configureContactPicketTemplate() {
        MBContactCollectionViewContactCell.appearance().tintColor = UIColor.ProtonMail.Blue_6789AB
        MBContactCollectionViewContactCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h4)
        MBContactCollectionViewPromptCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h4)
        MBContactCollectionViewEntryCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h4)
    }
    
    private func configureEncryptionPasswordField() {
        let passwordLeftPaddingView = UIView(frame: CGRectMake(0, 0, 12, self.encryptedPasswordTextField.frame.size.height))
        encryptedPasswordTextField.leftView = passwordLeftPaddingView
        encryptedPasswordTextField.leftViewMode = UITextFieldViewMode.Always
        
        let nextButton = UIButton()
        nextButton.addTarget(self, action: "didTapNextButton", forControlEvents: UIControlEvents.TouchUpInside)
        nextButton.setImage(UIImage(named: "next"), forState: UIControlState.Normal)
        nextButton.sizeToFit()
        
        let nextView = UIView(frame: CGRectMake(0, 0, nextButton.frame.size.width + 10, nextButton.frame.size.height))
        nextView.addSubview(nextButton)
        encryptedPasswordTextField.rightView = nextView
        encryptedPasswordTextField.rightViewMode = UITextFieldViewMode.Always
    }
    
    private func configureExpirationField() {
        let expirationLeftPaddingView = UIView(frame: CGRectMake(0, 0, 15, self.expirationDateTextField.frame.size.height))
        expirationDateTextField.leftView = expirationLeftPaddingView
        expirationDateTextField.leftViewMode = UITextFieldViewMode.Always
        
        let confirmButton = UIButton()
        confirmButton.addTarget(self, action: "didTapConfirmButton", forControlEvents: UIControlEvents.TouchUpInside)
        confirmButton.setImage(UIImage(named: "confirm_compose"), forState: UIControlState.Normal)
        confirmButton.sizeToFit()
        
        let confirmView = UIView(frame: CGRectMake(0, 0, confirmButton.frame.size.width + 10, confirmButton.frame.size.height))
        confirmView.addSubview(confirmButton)
        expirationDateTextField.rightView = confirmView
        expirationDateTextField.rightViewMode = UITextFieldViewMode.Always
        expirationDateTextField.delegate = self
    }
    
    private func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object:nil)
    }
    
    private func unregisterForKeybardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object:nil)
    }
    
    internal func didTapNextButton() {
        self.delegate?.composeViewDidTapNextButton(self)
    }
    
    private func configureErrorMessage() {
        self.errorView = UIView()
        self.errorView.backgroundColor = UIColor.whiteColor()
        self.errorView.clipsToBounds = true
        
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
            make.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
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

extension ComposeView: UIPickerViewDataSource {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return kNumberOfColumnsInTimePicker
    }
    

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0) {
            return kNumberOfDaysInTimePicker
        } else {
            return kNumberOfHoursInTimePicker
        }
    }
}

extension ComposeView: UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if (component == 0) {
            return "\(row) days"
        } else {
            return "\(row) hours"
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var selectedDay = pickerView.selectedRowInComponent(0)
        var selectedHour = pickerView.selectedRowInComponent(1)

        var day = "\(selectedDay) days"
        var hour = "\(selectedHour) hours"
        
        self.expirationDateTextField.text = "\(day) \(hour)"
    }
}

extension ComposeView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if (textField == expirationDateTextField) {
            return false
        }
        
        return true
    }
}