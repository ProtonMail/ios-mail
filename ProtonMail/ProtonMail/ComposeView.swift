//
//  ComposeView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//
import Foundation
import UIKit


protocol ComposeViewDelegate {
    func ComposeViewDidSizeChanged(size: CGSize)
    func ComposeViewDidOffsetChanged(offset: CGPoint)
    func composeViewDidTapNextButton(composeView: ComposeView)
    func composeViewDidTapEncryptedButton(composeView: ComposeView)
    func composeViewDidTapAttachmentButton(composeView: ComposeView)
    
    func composeView(composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    func composeView(composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    
    func composeViewHideExpirationView(composeView: ComposeView)
    func composeViewCancelExpirationData(composeView: ComposeView)
    func composeViewDidTapExpirationButton(composeView: ComposeView)
    func composeViewCollectExpirationData(composeView: ComposeView)
    
    func composeViewPickFrom(composeView: ComposeView)
}

protocol ComposeViewDataSource {
    func composeViewContactsModelForPicker(composeView: ComposeView, picker: MBContactPicker) -> [AnyObject]!
    func composeViewSelectedContactsForPicker(composeView: ComposeView, picker: MBContactPicker) -> [AnyObject]!
}

class ComposeView: UIViewController {
    
    var pickerHeight : CGFloat = 0;
    
    let kConfirmError : String = NSLocalizedString( "Message password does not match.")
    let kEmptyEOPWD : String = NSLocalizedString( "Password cannot be empty.")
    let kExpirationNeedsPWDError : String = NSLocalizedString("Please set a password.")
    
    var toContactPicker: MBContactPicker!
    var toContacts: String {
        return toContactPicker.contactList
    }
    
    var hasOutSideEmails : Bool {
        let toHas = toContactPicker.hasOutsideEmails
        if (toHas) {
            return true;
        }
        
        let ccHas = ccContactPicker.hasOutsideEmails
        if (ccHas) {
            return true;
        }
        
        let bccHas = bccContactPicker.hasOutsideEmails
        if (bccHas) {
            return true;
        }
        
        return false
    }
    var ccContactPicker: MBContactPicker!
    var ccContacts: String {
        return ccContactPicker.contactList
    }
    var bccContactPicker: MBContactPicker!
    var bccContacts: String {
        return bccContactPicker.contactList
    }
    
    var expirationTimeInterval: NSTimeInterval = 0
    
    var hasContent: Bool {//need check body also here
        return !toContacts.isEmpty || !ccContacts.isEmpty || !bccContacts.isEmpty || !subjectTitle.isEmpty
    }
    
    var subjectTitle: String {
        return subject.text ?? ""
    }
    
    // MARK : - Outlets
    @IBOutlet var fakeContactPickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subject: UITextField!
    @IBOutlet var showCcBccButton: UIButton!
    
    // MARK: - Action Buttons
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet var encryptedButton: UIButton!
    @IBOutlet var expirationButton: UIButton!
    @IBOutlet var attachmentButton: UIButton!
    private var confirmExpirationButton: UIButton!
    
    // MARK: - Encryption password
    @IBOutlet weak var passwordView: UIView!
    @IBOutlet var encryptedPasswordTextField: UITextField!
    @IBOutlet var encryptedActionButton: UIButton!
    
    
    // MARK: - Expiration Date
    @IBOutlet var expirationView: UIView!
    @IBOutlet var expirationDateTextField: UITextField!
    
    // MARK: - From field
    @IBOutlet weak var fromView: UIView!
    @IBOutlet weak var fromAddress: UILabel!
    @IBOutlet weak var fromPickerButton: UIButton!
    
    // MARK: - Delegate and Datasource
    var datasource: ComposeViewDataSource?
    var delegate: ComposeViewDelegate?
    
    var selfView : UIView!
    
    // MARK: - Constants
    private let kDefaultRecipientHeight = 44
    private let kErrorMessageHeight: CGFloat = 48.0
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int = 30
    private let kNumberOfHoursInTimePicker: Int = 24
    private let kCcBccContainerViewHeight: CGFloat = 96.0
    
    //
    private let kAnimationDuration = 0.25
    
    //
    private var errorView: ComposeErrorView!
    private var isShowingCcBccView: Bool = false
    private var hasExpirationSchedule: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selfView = self.view;
        
        self.configureContactPickerTemplate()
        self.includeButtonBorder(encryptedButton)
        self.includeButtonBorder(expirationButton)
        self.includeButtonBorder(attachmentButton)
        self.includeButtonBorder(encryptedPasswordTextField)
        self.includeButtonBorder(expirationDateTextField)
        
        self.configureToContactPicker()
        self.configureCcContactPicker()
        self.configureBccContactPicker()
        self.configureSubject()
        
        self.configureEncryptionPasswordField()
        self.configureExpirationField()
        self.configureErrorMessage()
        
        self.view.bringSubviewToFront(showCcBccButton)
        self.view.bringSubviewToFront(subject);
        self.view.sendSubviewToBack(ccContactPicker)
        self.view.sendSubviewToBack(bccContactPicker)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.notifyViewSize( false )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func contactPlusButtonTapped(sender: UIButton) {
        self.plusButtonHandle();
        self.notifyViewSize(true)
    }
    
    @IBAction func fromPickerAction(sender: AnyObject) {
        self.delegate?.composeViewPickFrom(self)
    }
    
    func updateFromValue (email: String , pickerEnabled : Bool) {
        fromAddress.text = email
        fromPickerButton.enabled = pickerEnabled
    }
    
    @IBAction func attachmentButtonTapped(sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.view.endEditing(true)
        self.delegate?.composeViewDidTapAttachmentButton(self)
    }
    
    func updateAttachmentButton(hasAtts: Bool) {
        if hasAtts {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment-active"), forState: UIControlState.Normal)
        } else {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment"), forState: UIControlState.Normal)
        }
    }
    
    @IBAction func expirationButtonTapped(sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.view.endEditing(true)
        self.toContactPicker.becomeFirstResponder()
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 0.0
            self.expirationView.alpha = 1.0
            
            self.toContactPicker.userInteractionEnabled = false
            self.ccContactPicker.userInteractionEnabled = false
            self.bccContactPicker.userInteractionEnabled = false
            self.subject.userInteractionEnabled = false
            
            self.showExpirationPicker()
            self.toContactPicker.resignFirstResponder()
        })
    }
    
    @IBAction func encryptedButtonTapped(sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.delegate?.composeViewDidTapEncryptedButton(self)
    }
    
    @IBAction func didTapExpirationDismissButton(sender: UIButton) {
        self.hideExpirationPicker()
    }
    
    @IBAction func didTapEncryptedDismissButton(sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        self.encryptedPasswordTextField.resignFirstResponder()
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.encryptedPasswordTextField.text = ""
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 1.0
        })
    }
    
    
    // Mark: -- Private Methods
    private func includeButtonBorder(view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.CGColor
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
        
        self.confirmExpirationButton = UIButton()
        confirmExpirationButton.addTarget(self, action: "didTapConfirmExpirationButton", forControlEvents: UIControlEvents.TouchUpInside)
        confirmExpirationButton.setImage(UIImage(named: "next"), forState: UIControlState.Normal)
        confirmExpirationButton.sizeToFit()
        
        let confirmView = UIView(frame: CGRectMake(0, 0, confirmExpirationButton.frame.size.width + 10, confirmExpirationButton.frame.size.height))
        confirmView.addSubview(confirmExpirationButton)
        expirationDateTextField.rightView = confirmView
        expirationDateTextField.rightViewMode = UITextFieldViewMode.Always
        expirationDateTextField.delegate = self
    }
    
    private func configureErrorMessage() {
        self.errorView = ComposeErrorView()
        self.errorView.backgroundColor = UIColor.whiteColor()
        self.errorView.clipsToBounds = true
        self.errorView.backgroundColor = UIColor.darkGrayColor()
        self.view.addSubview(errorView)
    }
    
    private func configureContactPickerTemplate() {
        MBContactCollectionViewContactCell.appearance().tintColor = UIColor.ProtonMail.Blue_6789AB
        MBContactCollectionViewContactCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h6)
        MBContactCollectionViewPromptCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h6)
        MBContactCollectionViewEntryCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h6)
    }
    
    ///
    internal func notifyViewSize(animation : Bool)
    {
        UIView.animateWithDuration(animation ? self.kAnimationDuration : 0, delay:0, options: nil, animations: {
            //143
            self.updateViewSize()
            PMLog.D("\(self.buttonView.frame)")
            PMLog.D("\(self.expirationView.frame)")
            PMLog.D("\(self.passwordView.frame)")
            let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height + self.pickerHeight)
            self.delegate?.ComposeViewDidSizeChanged(size)
            }, completion: nil)
    }
    
    internal func configureSubject() {
        //self.subject.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        //self.subject.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
        let subjectLeftPaddingView = UIView(frame: CGRectMake(0, 0, 12, self.subject.frame.size.height))
        self.subject.leftView = subjectLeftPaddingView
        self.subject.leftViewMode = UITextFieldViewMode.Always
        self.subject.autocapitalizationType = .Sentences
        
    }
    
    internal func plusButtonHandle()
    {
        if (isShowingCcBccView) {
            UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight
                self.ccContactPicker.alpha = 0.0
                self.bccContactPicker.alpha = 0.0
                self.showCcBccButton.setImage(UIImage(named: "compose_pluscontact"), forState:UIControlState.Normal )
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                self.ccContactPicker.alpha = 1.0
                self.bccContactPicker.alpha = 1.0
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight + self.ccContactPicker.currentContentHeight + self.bccContactPicker.currentContentHeight
                self.showCcBccButton.setImage(UIImage(named: "compose_minuscontact"), forState:UIControlState.Normal )
                self.view.layoutIfNeeded()
            })
        }
        
        isShowingCcBccView = !isShowingCcBccView
    }
    
    internal func didTapConfirmExpirationButton() {
        self.delegate?.composeViewCollectExpirationData(self)
    }
    
    internal func didTapNextButton() {
        self.delegate?.composeViewDidTapNextButton(self)
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
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Hint (Optional)")
        self.encryptedPasswordTextField.secureTextEntry = false
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showEncryptionDone() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Password")
        self.encryptedPasswordTextField.secureTextEntry = true
        self.encryptedButton.setImage(UIImage(named: "compose_lock-active"), forState: UIControlState.Normal)
    }
    
    internal func showEncryptionRemoved() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedButton.setImage(UIImage(named: "compose_lock"), forState: UIControlState.Normal)
    }
    
    internal func showExpirationPicker() {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.delegate?.composeViewDidTapExpirationButton(self)
        })
    }
    
    internal func hideExpirationPicker() {
        self.toContactPicker.userInteractionEnabled = true
        self.ccContactPicker.userInteractionEnabled = true
        self.bccContactPicker.userInteractionEnabled = true
        self.subject.userInteractionEnabled = true
        //self.htmlEditor.view.userInteractionEnabled = true
        
        UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
            self.expirationView.alpha = 0.0
            self.buttonView.alpha = 1.0
            self.delegate?.composeViewHideExpirationView(self)
        })
    }
    
    internal func showPasswordAndConfirmDoesntMatch(error : String) {
        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959

        self.errorView.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.left.equalTo()(self.selfView)
            update.right.equalTo()(self.selfView)
            update.height.equalTo()(self.kErrorMessageHeight)
            update.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        self.errorView.setError(error, withShake: true)
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            
        })
    }
    
    internal func hidePasswordAndConfirmDoesntMatch() {
        self.errorView.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.left.equalTo()(self.view)
            update.right.equalTo()(self.view)
            update.height.equalTo()(0)
            update.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            //self.layoutIfNeeded()
        })
    }
    
    func updateExpirationValue(intagerV : NSTimeInterval, text : String)
    {
        self.expirationDateTextField.text = text
        self.expirationTimeInterval = intagerV
    }
    
    func setExpirationValue (day : Int, hour : Int) -> Bool
    {
        if (day == 0 && hour == 0 && !hasExpirationSchedule) {
            self.expirationDateTextField.shake(3, offset: 10.0)
            
            return false
            
        } else {
            if (!hasExpirationSchedule) {
                self.expirationButton.setImage(UIImage(named: "compose_expiration-active"), forState: UIControlState.Normal)
                self.confirmExpirationButton.setImage(UIImage(named: "cancel_compose"), forState: UIControlState.Normal)
            } else {
                self.expirationDateTextField.text = ""
                self.expirationTimeInterval  = 0;
                self.expirationButton.setImage(UIImage(named: "compose_expiration"), forState: UIControlState.Normal)
                self.confirmExpirationButton.setImage(UIImage(named: "next"), forState: UIControlState.Normal)
                self.delegate?.composeViewCancelExpirationData(self)
                
            }
            hasExpirationSchedule = !hasExpirationSchedule
            self.hideExpirationPicker()
            return true
        }
    }
    
    private func updateViewSize()
    {
        let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height)
        //self.htmlEditor.view.frame = CGRect(x: 0, y: size.height, width: editorSize.width, height: editorSize.height)
        //self.htmlEditor.setFrame(CGRect(x: 0, y: 0, width: editorSize.width, height: editorSize.height))
    }
    
    private func configureToContactPicker() {
        toContactPicker = MBContactPicker()
        toContactPicker.setTranslatesAutoresizingMaskIntoConstraints(true)
        toContactPicker.cellHeight = self.kDefaultRecipientHeight;
        self.view.addSubview(toContactPicker)
        toContactPicker.datasource = self
        toContactPicker.delegate = self
        
        toContactPicker.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.fromView.mas_bottom).with().offset()(5)
            make.left.equalTo()(self.selfView)
            make.right.equalTo()(self.selfView)
            make.height.equalTo()(self.kDefaultRecipientHeight)
        }
    }
    
    private func configureCcContactPicker() {
        ccContactPicker = MBContactPicker()
        self.view.addSubview(ccContactPicker)
        
        ccContactPicker.datasource = self
        ccContactPicker.delegate = self
        ccContactPicker.alpha = 0.0
        
        ccContactPicker.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.toContactPicker.mas_bottom)
            make.left.equalTo()(self.selfView)
            make.right.equalTo()(self.selfView)
            make.height.equalTo()(self.toContactPicker)
        }
    }
    
    private func configureBccContactPicker() {
        bccContactPicker = MBContactPicker()
        self.view.addSubview(bccContactPicker)
        
        bccContactPicker.datasource = self
        bccContactPicker.delegate = self
        bccContactPicker.alpha = 0.0
        
        bccContactPicker.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.ccContactPicker.mas_bottom)
            make.left.equalTo()(self.selfView)
            make.right.equalTo()(self.selfView)
            make.height.equalTo()(self.ccContactPicker)
        }
    }
    
    private func updateContactPickerHeight(contactPicker: MBContactPicker, newHeight: CGFloat) {
        if (contactPicker == self.toContactPicker) {
            toContactPicker.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.top.equalTo()(self.fromView.mas_bottom)
                make.left.equalTo()(self.selfView)
                make.right.equalTo()(self.selfView)
                make.height.equalTo()(newHeight)
            })
        }
        else if (contactPicker == self.ccContactPicker) {
            ccContactPicker.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.top.equalTo()(self.toContactPicker.mas_bottom)
                make.left.equalTo()(self.selfView)
                make.right.equalTo()(self.selfView)
                make.height.equalTo()(newHeight)
            })
        } else if (contactPicker == self.bccContactPicker) {
            bccContactPicker.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.top.equalTo()(self.ccContactPicker.mas_bottom)
                make.left.equalTo()(self.selfView)
                make.right.equalTo()(self.selfView)
                make.height.equalTo()(newHeight)
            })
        }
        
        if (isShowingCcBccView) {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight + ccContactPicker.currentContentHeight + bccContactPicker.currentContentHeight
        } else {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight
        }
        
        
        UIView.animateWithDuration(NSTimeInterval(contactPicker.animationSpeed), animations: { () -> Void in
            self.view.layoutIfNeeded()
            contactPicker.contactCollectionView.addBorder(.Bottom, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
            //contactPicker.contactCollectionView.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
            //contactPicker.contactCollectionView.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        })
    }
}




// MARK: - MBContactPickerDataSource
extension ComposeView: MBContactPickerDataSource {
    func contactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        if (contactPickerView == toContactPicker) {
            contactPickerView.prompt = NSLocalizedString("To:")
        } else if (contactPickerView == ccContactPicker) {
            contactPickerView.prompt = NSLocalizedString("Cc:")
        } else if (contactPickerView == bccContactPicker) {
            contactPickerView.prompt = NSLocalizedString("Bcc:")
        }
        
        //contactPickerView.contactCollectionView.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        //contactPickerView.contactCollectionView.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
        return self.datasource?.composeViewContactsModelForPicker(self, picker: contactPickerView)
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        return self.datasource?.composeViewSelectedContactsForPicker(self, picker: contactPickerView)
    }
}


// MARK: - MBContactPickerDelegate

extension ComposeView: MBContactPickerDelegate {
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didAddContact model: MBContactPickerModelProtocol!) {
        let contactPicker = contactPickerForContactCollectionView(contactCollectionView)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didAddContact: model as! ContactVO, toPicker: contactPicker)
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didRemoveContact model: MBContactPickerModelProtocol!) {
        let contactPicker = contactPickerForContactCollectionView(contactCollectionView)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didRemoveContact: model as! ContactVO, fromPicker: contactPicker)
    }
    
    func contactPicker(contactPicker: MBContactPicker!, didEnterCustomText text: String!, needFocus focus: Bool) {
        let customContact = ContactVO(id: "", name: text, email: text)
        contactPicker.addToSelectedContacts(customContact, needFocus: focus)
    }
    
    func contactPicker(contactPicker: MBContactPicker!, didUpdateContentHeightTo newHeight: CGFloat) {
        self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
    }
    
    func didShowFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        self.view.bringSubviewToFront(contactPicker)
        if (contactPicker.frame.size.height <= contactPicker.currentContentHeight) {
            let pickerRectInWindow = self.view.convertRect(contactPicker.frame, toView: nil)
            let newHeight = self.view.window!.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight
            self.pickerHeight = newHeight
            self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
        }
        
        if !contactPicker.hidden {
            
        }
        
        self.notifyViewSize(false)
    }
    
    func didHideFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        self.view.sendSubviewToBack(contactPicker)
        if (contactPicker.frame.size.height > contactPicker.currentContentHeight) {
            self.updateContactPickerHeight(contactPicker, newHeight: contactPicker.currentContentHeight)
        }
        
        self.pickerHeight = 0;
        self.notifyViewSize(false)
    }
    
    // MARK: Private delegate helper methods
    
    private func contactPickerForContactCollectionView(contactCollectionView: MBContactCollectionView) -> MBContactPicker {
        var contactPicker: MBContactPicker = toContactPicker
        if (contactCollectionView == toContactPicker.contactCollectionView) {
            contactPicker = toContactPicker
        }
        else if (contactCollectionView == ccContactPicker.contactCollectionView) {
            contactPicker = ccContactPicker
        } else if (contactCollectionView == bccContactPicker.contactCollectionView) {
            contactPicker = bccContactPicker
        }
        return contactPicker
    }
    internal func customFilterPredicate(searchString: String!) -> NSPredicate! {
        return NSPredicate(format: "contactTitle CONTAINS[cd] %@ or contactSubtitle CONTAINS[cd] %@", argumentArray: [searchString, searchString])
    }
}

// MARK: - UITextFieldDelegate
extension ComposeView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if (textField == expirationDateTextField) {
            return false
        }
        return true
    }
}

// MARK: - MBContactPicker extension
extension MBContactPicker {
    var contactList: String {
        var contactList = ""
        let contactsSelected = NSArray(array: self.contactsSelected)
        if let contacts = contactsSelected.valueForKey(ContactVO.Attributes.email) as? [String] {
            contactList = ", ".join(contacts)
        }
        return contactList
    }
    
    var hasOutsideEmails: Bool {
        let contactsSelected = NSArray(array: self.contactsSelected)
        if let contacts = contactsSelected.valueForKey(ContactVO.Attributes.email) as? [String] {
            for contact in contacts {
                if contact.lowercaseString.rangeOfString("@protonmail.ch") == nil && contact.lowercaseString.rangeOfString("@protonmail.com") == nil {
                    return true
                }
            }
        }
        return false
    }
}

