//
//  ComposeViewN.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//
import Foundation
import UIKit



protocol ComposeViewNDelegate {
    func ComposeViewNDidSizeChanged(size: CGSize)
    func ComposeViewNDidOffsetChanged(offset: CGPoint)
    func composeViewDidTapNextButton(composeView: ComposeViewN)
    func composeViewDidTapEncryptedButton(composeView: ComposeViewN)
    func composeViewDidTapAttachmentButton(composeView: ComposeViewN)
    
    func composeView(composeView: ComposeViewN, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    func composeView(composeView: ComposeViewN, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    
    func composeViewHideExpirationView(composeView: ComposeViewN)
    func composeViewCancelExpirationData(composeView: ComposeViewN)
    func composeViewDidTapExpirationButton(composeView: ComposeViewN)
    func composeViewCollectExpirationData(composeView: ComposeViewN)
}

protocol ComposeViewNDataSource {
    func composeViewContactsModelForPicker(composeView: ComposeViewN, picker: MBContactPicker) -> [AnyObject]!
    func composeViewSelectedContactsForPicker(composeView: ComposeViewN, picker: MBContactPicker) -> [AnyObject]!
}

class ComposeViewN: UIViewController {

    let kConfirmError : String = NSLocalizedString( "Message password doesn't match.")
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
    
    // MARK : - HtmlEditor
    var htmlEditor : HtmlEditorViewController!
    private var screenSize : CGRect!
    private var editorSize : CGSize!
    
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
    
    
    // MARK: - Delegate and Datasource
    var datasource: ComposeViewNDataSource?
    var delegate: ComposeViewNDelegate?
    
    var selfView : UIView!
    
    // MARK: - Constants
    private let kDefaultRecipientHeight: CGFloat = 48.0
    private let kErrorMessageHeight: CGFloat = 48.0
    private let kNumberOfColumnsInTimePicker: Int = 2
    private let kNumberOfDaysInTimePicker: Int = 30
    private let kNumberOfHoursInTimePicker: Int = 24
    private let kCcBccContainerViewHeight: CGFloat = 96.0
    
    //
    private let kAnimationDuration = 0.25
    
    //
    private var errorView: UIView!
    private var errorTextView: UITextView!
    private var isShowingCcBccView: Bool = false
    private var hasExpirationSchedule: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selfView = self.view;
        self.screenSize = UIScreen.mainScreen().bounds
        
        self.configureContactPickerTemplate()
        self.includeButtonBorder(encryptedButton)
        self.includeButtonBorder(expirationButton)
        self.includeButtonBorder(attachmentButton)
        self.includeButtonBorder(encryptedPasswordTextField)
        self.includeButtonBorder(expirationDateTextField)
        
        self.configureHtmlEditor()
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
        
        
        errorView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.selfView)
            make.right.equalTo()(self.selfView)
            make.height.equalTo()(0)
            make.top.equalTo()(self.passwordView.mas_bottom)
        }
        
        errorTextView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.selfView)
            make.right.equalTo()(self.selfView)
            make.height.equalTo()(self.errorTextView.frame.size.height)
            make.top.equalTo()(self.errorView).with().offset()(8)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func contactPlusButtonTapped(sender: UIButton) {
        self.plusButtonHandle();
        self.notifyViewSize(true)
    }
    
    @IBAction func attachmentButtonTapped(sender: UIButton) {
        self.view.endEditing(true)
        self.delegate?.composeViewDidTapAttachmentButton(self)
    }
    
    @IBAction func expirationButtonTapped(sender: UIButton) {
        self.view.endEditing(true)
        self.toContactPicker.becomeFirstResponder()
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 0.0
            self.expirationView.alpha = 1.0
            
            self.toContactPicker.userInteractionEnabled = false
            self.ccContactPicker.userInteractionEnabled = false
            self.bccContactPicker.userInteractionEnabled = false
            self.subject.userInteractionEnabled = false
            self.htmlEditor.view.userInteractionEnabled = false
            
            self.showExpirationPicker()
            self.toContactPicker.resignFirstResponder()
        })
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
    
    @IBAction func didTapExpirationDismissButton(sender: UIButton) {
        self.hideExpirationPicker()
    }
    
    @IBAction func didTapEncryptedDismissButton(sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        self.encryptedPasswordTextField.resignFirstResponder()
        UIView.animateWithDuration(0.3, animations: { () -> Void in
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
        self.errorView = UIView()
        self.errorView.backgroundColor = UIColor.whiteColor()
        self.errorView.clipsToBounds = true
        
        self.errorTextView = UITextView()
        self.errorTextView.backgroundColor = UIColor.clearColor()
        self.errorTextView.font = UIFont.robotoLight(size: UIFont.Size.h4)
        self.errorTextView.textAlignment = NSTextAlignment.Center
        self.errorTextView.textColor = UIColor.whiteColor()
        self.errorTextView.sizeToFit()
        self.view.addSubview(errorView)
        errorView.addSubview(errorTextView)
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
            println("\(self.buttonView.frame)")
            println("\(self.expirationView.frame)")
            println("\(self.passwordView.frame)")
            let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height + self.editorSize.height)
            self.delegate?.ComposeViewNDidSizeChanged(size)
            }, completion: nil)
    }
    
    internal func configureSubject() {
        self.subject.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        self.subject.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
        let subjectLeftPaddingView = UIView(frame: CGRectMake(0, 0, 12, self.subject.frame.size.height))
        self.subject.leftView = subjectLeftPaddingView
        self.subject.leftViewMode = UITextFieldViewMode.Always
    }
    
    internal func plusButtonHandle()
    {
        if (isShowingCcBccView) {
            UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight
                self.ccContactPicker.alpha = 0.0
                self.bccContactPicker.alpha = 0.0
                self.showCcBccButton.setImage(UIImage(named: "plus_compose"), forState:UIControlState.Normal )
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animateWithDuration(self.kAnimationDuration, animations: { () -> Void in
                self.ccContactPicker.alpha = 1.0
                self.bccContactPicker.alpha = 1.0
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight + self.ccContactPicker.currentContentHeight + self.bccContactPicker.currentContentHeight
                self.showCcBccButton.setImage(UIImage(named: "minus_compose"), forState:UIControlState.Normal )
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
        self.encryptedButton.setImage(UIImage(named: "encrypted_compose_checked"), forState: UIControlState.Normal)
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
        self.htmlEditor.view.userInteractionEnabled = true
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.expirationView.alpha = 0.0
            self.buttonView.alpha = 1.0
            self.delegate?.composeViewHideExpirationView(self)
        })
    }
    
    internal func showPasswordAndConfirmDoesntMatch(error : String) {
        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959
        self.errorTextView.text = error
        self.errorView.mas_updateConstraints { (update) -> Void in
            update.removeExisting = true
            update.left.equalTo()(self.selfView)
            update.right.equalTo()(self.selfView)
            update.height.equalTo()(self.kErrorMessageHeight)
            update.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        self.errorTextView.shake(3, offset: 10)
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            //self.layoutIfNeeded()
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
        if (day == 0 && hour == 0) {
            self.expirationDateTextField.shake(3, offset: 10.0)
            
            return false
            
        } else {
            if (!hasExpirationSchedule) {
                self.expirationButton.setImage(UIImage(named: "expiration_compose_checked"), forState: UIControlState.Normal)
                self.confirmExpirationButton.setImage(UIImage(named: "cancel_compose"), forState: UIControlState.Normal)
            } else {
                self.expirationDateTextField.text = ""
                self.expirationTimeInterval  = 0;
                self.expirationButton.setImage(UIImage(named: "expiration_compose"), forState: UIControlState.Normal)
                self.confirmExpirationButton.setImage(UIImage(named: "next"), forState: UIControlState.Normal)
                self.delegate?.composeViewCancelExpirationData(self)
                
            }
            hasExpirationSchedule = !hasExpirationSchedule
            self.hideExpirationPicker()
            return true
        }
    }
    
    private func configureHtmlEditor(){
        
        self.editorSize = CGSize.zeroSize
        self.htmlEditor = HtmlEditorViewController()
        self.htmlEditor.delegate = self
        self.view.addSubview(htmlEditor.view);
        let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height)
        self.htmlEditor.view.frame = CGRect(x: 0, y: size.height, width: screenSize.width, height: 1000)
        self.htmlEditor.setFrame(CGRect(x: 0, y: 0, width: screenSize.width, height: 1000))
    }
    
    private func updateViewSize()
    {
        let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height)
        self.htmlEditor.view.frame = CGRect(x: 0, y: size.height, width: editorSize.width, height: editorSize.height)
        self.htmlEditor.setFrame(CGRect(x: 0, y: 0, width: editorSize.width, height: editorSize.height))
    }
    
    private func configureToContactPicker() {
        toContactPicker = MBContactPicker()
        toContactPicker.setTranslatesAutoresizingMaskIntoConstraints(true)
        self.view.addSubview(toContactPicker)
        toContactPicker.datasource = self
        toContactPicker.delegate = self
        
        toContactPicker.mas_makeConstraints { (make) -> Void in
            make.top.equalTo()(self.selfView).with().offset()(5)
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
                make.top.equalTo()(self.selfView)
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
            contactPicker.contactCollectionView.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
            contactPicker.contactCollectionView.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        })
    }
}


//html editor delegate
extension ComposeViewN : HtmlEditorViewControllerDelegate {
    func editorSizeChanged(size: CGSize) {
        if( self.editorSize != size)
        {
            self.editorSize = size
            self.notifyViewSize(false)
        }
    }
    
    func editorCaretPosition(position: Int) {
        let x = self.htmlEditor.view.frame.origin.y
        println("x: \(x) -- top : \(position)")
        let offset = CGPoint(x: 0,y: x + CGFloat(position))
        self.delegate?.ComposeViewNDidOffsetChanged(offset)
    }
}

// MARK: - MBContactPickerDataSource
extension ComposeViewN: MBContactPickerDataSource {
    func contactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        if (contactPickerView == toContactPicker) {
            contactPickerView.prompt = NSLocalizedString("To:")
        } else if (contactPickerView == ccContactPicker) {
            contactPickerView.prompt = NSLocalizedString("Cc:")
        } else if (contactPickerView == bccContactPicker) {
            contactPickerView.prompt = NSLocalizedString("Bcc:")
        }
        
        contactPickerView.contactCollectionView.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        contactPickerView.contactCollectionView.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
        return self.datasource?.composeViewContactsModelForPicker(self, picker: contactPickerView)
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        return self.datasource?.composeViewSelectedContactsForPicker(self, picker: contactPickerView)
    }
}


// MARK: - MBContactPickerDelegate

extension ComposeViewN: MBContactPickerDelegate {
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didAddContact model: MBContactPickerModelProtocol!) {
        let contactPicker = contactPickerForContactCollectionView(contactCollectionView)
        
        self.delegate?.composeView(self, didAddContact: model as! ContactVO, toPicker: contactPicker)
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didRemoveContact model: MBContactPickerModelProtocol!) {
        let contactPicker = contactPickerForContactCollectionView(contactCollectionView)
        
        self.delegate?.composeView(self, didRemoveContact: model as! ContactVO, fromPicker: contactPicker)
    }
    
    func contactPicker(contactPicker: MBContactPicker!, didEnterCustomText text: String!) {
        let customContact = ContactVO(id: "", name: text, email: text)
        
        contactPicker.addToSelectedContacts(customContact)
    }
    
    func contactPicker(contactPicker: MBContactPicker!, didUpdateContentHeightTo newHeight: CGFloat) {
        self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
    }
    
    func didShowFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        self.view.bringSubviewToFront(contactPicker)
        if (contactPicker.frame.size.height <= contactPicker.currentContentHeight) {
            let pickerRectInWindow = self.view.convertRect(contactPicker.frame, toView: nil)
            let newHeight = self.view.window!.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight
            self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
        }
        
        if !contactPicker.hidden {
            
        }
        
    }
    
    func didHideFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        self.view.sendSubviewToBack(contactPicker)
        if (contactPicker.frame.size.height > contactPicker.currentContentHeight) {
            self.updateContactPickerHeight(contactPicker, newHeight: contactPicker.currentContentHeight)
        }
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
extension ComposeViewN: UITextFieldDelegate {
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

