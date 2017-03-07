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
    func ComposeViewDidSizeChanged(_ size: CGSize)
    func ComposeViewDidOffsetChanged(_ offset: CGPoint)
    func composeViewDidTapNextButton(_ composeView: ComposeView)
    func composeViewDidTapEncryptedButton(_ composeView: ComposeView)
    func composeViewDidTapAttachmentButton(_ composeView: ComposeView)
    
    func composeView(_ composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    func composeView(_ composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    
    func composeViewHideExpirationView(_ composeView: ComposeView)
    func composeViewCancelExpirationData(_ composeView: ComposeView)
    func composeViewDidTapExpirationButton(_ composeView: ComposeView)
    func composeViewCollectExpirationData(_ composeView: ComposeView)
    
    func composeViewPickFrom(_ composeView: ComposeView)
}

protocol ComposeViewDataSource {
    func composeViewContactsModelForPicker(_ composeView: ComposeView, picker: MBContactPicker) -> [AnyObject]!
    func composeViewSelectedContactsForPicker(_ composeView: ComposeView, picker: MBContactPicker) -> [AnyObject]!
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
    
    var expirationTimeInterval: TimeInterval = 0
    
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
    fileprivate var confirmExpirationButton: UIButton!
    
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
    fileprivate let kDefaultRecipientHeight = 44
    fileprivate let kErrorMessageHeight: CGFloat = 48.0
    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    fileprivate let kNumberOfHoursInTimePicker: Int = 24
    fileprivate let kCcBccContainerViewHeight: CGFloat = 96.0
    
    //
    fileprivate let kAnimationDuration = 0.25
    
    //
    fileprivate var errorView: ComposeErrorView!
    fileprivate var isShowingCcBccView: Bool = false
    fileprivate var hasExpirationSchedule: Bool = false
    
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
        
        self.view.bringSubview(toFront: showCcBccButton)
        self.view.bringSubview(toFront: subject);
        self.view.sendSubview(toBack: ccContactPicker)
        self.view.sendSubview(toBack: bccContactPicker)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.notifyViewSize( false )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func contactPlusButtonTapped(_ sender: UIButton) {
        self.plusButtonHandle();
        self.notifyViewSize(true)
    }
    
    @IBAction func fromPickerAction(_ sender: AnyObject) {
        self.delegate?.composeViewPickFrom(self)
    }
    
    func updateFromValue (_ email: String , pickerEnabled : Bool) {
        fromAddress.text = email
        fromPickerButton.isEnabled = pickerEnabled
    }
    
    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.view.endEditing(true)
        self.delegate?.composeViewDidTapAttachmentButton(self)
    }
    
    func updateAttachmentButton(_ hasAtts: Bool) {
        if hasAtts {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment-active"), for: UIControlState())
        } else {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment"), for: UIControlState())
        }
    }
    
    @IBAction func expirationButtonTapped(_ sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.view.endEditing(true)
        self.toContactPicker.becomeFirstResponder()
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 0.0
            self.expirationView.alpha = 1.0
            
            self.toContactPicker.isUserInteractionEnabled = false
            self.ccContactPicker.isUserInteractionEnabled = false
            self.bccContactPicker.isUserInteractionEnabled = false
            self.subject.isUserInteractionEnabled = false
            
            self.showExpirationPicker()
            self.toContactPicker.resignFirstResponder()
        })
    }
    
    @IBAction func encryptedButtonTapped(_ sender: UIButton) {
        self.hidePasswordAndConfirmDoesntMatch()
        self.delegate?.composeViewDidTapEncryptedButton(self)
    }
    
    @IBAction func didTapExpirationDismissButton(_ sender: UIButton) {
        self.hideExpirationPicker()
    }
    
    @IBAction func didTapEncryptedDismissButton(_ sender: UIButton) {
        self.delegate?.composeViewDidTapEncryptedButton(self)
        self.encryptedPasswordTextField.resignFirstResponder()
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.encryptedPasswordTextField.text = ""
            self.passwordView.alpha = 0.0
            self.buttonView.alpha = 1.0
        })
    }
    
    
    // Mark: -- Private Methods
    fileprivate func includeButtonBorder(_ view: UIView) {
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.cgColor
    }
    
    fileprivate func configureEncryptionPasswordField() {
        let passwordLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: self.encryptedPasswordTextField.frame.size.height))
        encryptedPasswordTextField.leftView = passwordLeftPaddingView
        encryptedPasswordTextField.leftViewMode = UITextFieldViewMode.always
        
        let nextButton = UIButton()
        nextButton.addTarget(self, action: #selector(ComposeView.didTapNextButton), for: UIControlEvents.touchUpInside)
        nextButton.setImage(UIImage(named: "next"), for: UIControlState())
        nextButton.sizeToFit()
        
        let nextView = UIView(frame: CGRect(x: 0, y: 0, width: nextButton.frame.size.width + 10, height: nextButton.frame.size.height))
        nextView.addSubview(nextButton)
        encryptedPasswordTextField.rightView = nextView
        encryptedPasswordTextField.rightViewMode = UITextFieldViewMode.always
    }
    
    fileprivate func configureExpirationField() {
        let expirationLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: self.expirationDateTextField.frame.size.height))
        expirationDateTextField.leftView = expirationLeftPaddingView
        expirationDateTextField.leftViewMode = UITextFieldViewMode.always
        
        self.confirmExpirationButton = UIButton()
        confirmExpirationButton.addTarget(self, action: #selector(ComposeView.didTapConfirmExpirationButton), for: UIControlEvents.touchUpInside)
        confirmExpirationButton.setImage(UIImage(named: "next"), for: UIControlState())
        confirmExpirationButton.sizeToFit()
        
        let confirmView = UIView(frame: CGRect(x: 0, y: 0, width: confirmExpirationButton.frame.size.width + 10, height: confirmExpirationButton.frame.size.height))
        confirmView.addSubview(confirmExpirationButton)
        expirationDateTextField.rightView = confirmView
        expirationDateTextField.rightViewMode = UITextFieldViewMode.always
        expirationDateTextField.delegate = self
    }
    
    fileprivate func configureErrorMessage() {
        self.errorView = ComposeErrorView()
        self.errorView.backgroundColor = UIColor.white
        self.errorView.clipsToBounds = true
        self.errorView.backgroundColor = UIColor.darkGray
        self.view.addSubview(errorView)
    }
    
    fileprivate func configureContactPickerTemplate() {
        MBContactCollectionViewContactCell.appearance().tintColor = UIColor.ProtonMail.Blue_6789AB
        MBContactCollectionViewContactCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h6)
        MBContactCollectionViewPromptCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h6)
        MBContactCollectionViewEntryCell.appearance().font = UIFont.robotoLight(size: UIFont.Size.h6)
    }
    
    ///
    internal func notifyViewSize(_ animation : Bool)
    {
        UIView.animate(withDuration: animation ? self.kAnimationDuration : 0, delay:0, options: UIViewAnimationOptions(), animations: {
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
        
        let subjectLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: self.subject.frame.size.height))
        self.subject.leftView = subjectLeftPaddingView
        self.subject.leftViewMode = UITextFieldViewMode.always
        self.subject.autocapitalizationType = .sentences
        
    }
    
    internal func plusButtonHandle()
    {
        if (isShowingCcBccView) {
            UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight
                self.ccContactPicker.alpha = 0.0
                self.bccContactPicker.alpha = 0.0
                self.showCcBccButton.setImage(UIImage(named: "compose_pluscontact"), for:UIControlState() )
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
                self.ccContactPicker.alpha = 1.0
                self.bccContactPicker.alpha = 1.0
                self.fakeContactPickerHeightConstraint.constant = self.toContactPicker.currentContentHeight + self.ccContactPicker.currentContentHeight + self.bccContactPicker.currentContentHeight
                self.showCcBccButton.setImage(UIImage(named: "compose_minuscontact"), for:UIControlState() )
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
        self.encryptedPasswordTextField.isSecureTextEntry = true
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showConfirmPasswordView() {
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Confirm Password")
        self.encryptedPasswordTextField.isSecureTextEntry = true
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showPasswordHintView() {
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Hint (Optional)")
        self.encryptedPasswordTextField.isSecureTextEntry = false
        self.encryptedPasswordTextField.text = ""
    }
    
    internal func showEncryptionDone() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedPasswordTextField.placeholder = NSLocalizedString("Define Password")
        self.encryptedPasswordTextField.isSecureTextEntry = true
        self.encryptedButton.setImage(UIImage(named: "compose_lock-active"), for: UIControlState())
    }
    
    internal func showEncryptionRemoved() {
        didTapEncryptedDismissButton(encryptedButton)
        self.encryptedButton.setImage(UIImage(named: "compose_lock"), for: UIControlState())
    }
    
    internal func showExpirationPicker() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.delegate?.composeViewDidTapExpirationButton(self)
        })
    }
    
    internal func hideExpirationPicker() {
        self.toContactPicker.isUserInteractionEnabled = true
        self.ccContactPicker.isUserInteractionEnabled = true
        self.bccContactPicker.isUserInteractionEnabled = true
        self.subject.isUserInteractionEnabled = true
        //self.htmlEditor.view.userInteractionEnabled = true
        
        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
            self.expirationView.alpha = 0.0
            self.buttonView.alpha = 1.0
            self.delegate?.composeViewHideExpirationView(self)
        })
    }
    
    internal func showPasswordAndConfirmDoesntMatch(_ error : String) {
        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959
        
        self.errorView.mas_updateConstraints { (update) -> Void in
            update?.removeExisting = true
            let _ = update?.left.equalTo()(self.selfView)
            let _ = update?.right.equalTo()(self.selfView)
            let _ = update?.height.equalTo()(self.kErrorMessageHeight)
            let _ = update?.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        self.errorView.setError(error, withShake: true)
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            
        })
    }
    
    internal func hidePasswordAndConfirmDoesntMatch() {
        self.errorView.mas_updateConstraints { (update) -> Void in
            update?.removeExisting = true
            let _ = update?.left.equalTo()(self.view)
            let _ = update?.right.equalTo()(self.view)
            let _ = update?.height.equalTo()(0)
            let _ = update?.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
        }
        
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            //self.layoutIfNeeded()
        })
    }
    
    func updateExpirationValue(_ intagerV : TimeInterval, text : String)
    {
        self.expirationDateTextField.text = text
        self.expirationTimeInterval = intagerV
    }
    
    func setExpirationValue (_ day : Int, hour : Int) -> Bool
    {
        if (day == 0 && hour == 0 && !hasExpirationSchedule) {
            self.expirationDateTextField.shake(3, offset: 10.0)
            
            return false
            
        } else {
            if (!hasExpirationSchedule) {
                self.expirationButton.setImage(UIImage(named: "compose_expiration-active"), for: UIControlState())
                self.confirmExpirationButton.setImage(UIImage(named: "cancel_compose"), for: UIControlState())
            } else {
                self.expirationDateTextField.text = ""
                self.expirationTimeInterval  = 0;
                self.expirationButton.setImage(UIImage(named: "compose_expiration"), for: UIControlState())
                self.confirmExpirationButton.setImage(UIImage(named: "next"), for: UIControlState())
                self.delegate?.composeViewCancelExpirationData(self)
                
            }
            hasExpirationSchedule = !hasExpirationSchedule
            self.hideExpirationPicker()
            return true
        }
    }
    
    fileprivate func updateViewSize()
    {
        //let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height)
        //self.htmlEditor.view.frame = CGRect(x: 0, y: size.height, width: editorSize.width, height: editorSize.height)
        //self.htmlEditor.setFrame(CGRect(x: 0, y: 0, width: editorSize.width, height: editorSize.height))
    }
    
    fileprivate func configureToContactPicker() {
        toContactPicker = MBContactPicker()
        toContactPicker.translatesAutoresizingMaskIntoConstraints = true
        toContactPicker.cellHeight = self.kDefaultRecipientHeight;
        self.view.addSubview(toContactPicker)
        toContactPicker.datasource = self
        toContactPicker.delegate = self
        
        toContactPicker.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.fromView.mas_bottom)?.with().offset()(5)
            let _ = make?.left.equalTo()(self.selfView)
            let _ = make?.right.equalTo()(self.selfView)
            let _ = make?.height.equalTo()(self.kDefaultRecipientHeight)
        }
    }
    
    fileprivate func configureCcContactPicker() {
        ccContactPicker = MBContactPicker()
        self.view.addSubview(ccContactPicker)
        
        ccContactPicker.datasource = self
        ccContactPicker.delegate = self
        ccContactPicker.alpha = 0.0
        
        ccContactPicker.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.toContactPicker.mas_bottom)
            let _ = make?.left.equalTo()(self.selfView)
            let _ = make?.right.equalTo()(self.selfView)
            let _ = make?.height.equalTo()(self.toContactPicker)
        }
    }
    
    fileprivate func configureBccContactPicker() {
        bccContactPicker = MBContactPicker()
        self.view.addSubview(bccContactPicker)
        
        bccContactPicker.datasource = self
        bccContactPicker.delegate = self
        bccContactPicker.alpha = 0.0
        
        bccContactPicker.mas_makeConstraints { (make) -> Void in
            let _ = make?.top.equalTo()(self.ccContactPicker.mas_bottom)
            let _ = make?.left.equalTo()(self.selfView)
            let _ = make?.right.equalTo()(self.selfView)
            let _ = make?.height.equalTo()(self.ccContactPicker)
        }
    }
    
    fileprivate func updateContactPickerHeight(_ contactPicker: MBContactPicker, newHeight: CGFloat) {
        if (contactPicker == self.toContactPicker) {
            toContactPicker.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.top.equalTo()(self.fromView.mas_bottom)
                let _ = make?.left.equalTo()(self.selfView)
                let _ = make?.right.equalTo()(self.selfView)
                let _ = make?.height.equalTo()(newHeight)
            })
        }
        else if (contactPicker == self.ccContactPicker) {
            ccContactPicker.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.top.equalTo()(self.toContactPicker.mas_bottom)
                let _ = make?.left.equalTo()(self.selfView)
                let _ = make?.right.equalTo()(self.selfView)
                let _ = make?.height.equalTo()(newHeight)
            })
        } else if (contactPicker == self.bccContactPicker) {
            bccContactPicker.mas_updateConstraints({ (make) -> Void in
                make?.removeExisting = true
                let _ = make?.top.equalTo()(self.ccContactPicker.mas_bottom)
                let _ = make?.left.equalTo()(self.selfView)
                let _ = make?.right.equalTo()(self.selfView)
                let _ = make?.height.equalTo()(newHeight)
            })
        }
        
        if (isShowingCcBccView) {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight + ccContactPicker.currentContentHeight + bccContactPicker.currentContentHeight
        } else {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight
        }
        contactPicker.contactCollectionView!.addBorder(.bottom, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
//        UIView.animateWithDuration(NSTimeInterval(contactPicker.animationSpeed), animations: { () -> Void in
//            //self.view.layoutIfNeeded()
//            contactPicker.contactCollectionView!.addBorder(.Bottom, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
//            //contactPicker.contactCollectionView.addBorder(.Left, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
//            //contactPicker.contactCollectionView.addBorder(.Right, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
//        })
    }
}




// MARK: - MBContactPickerDataSource
extension ComposeView: MBContactPickerDataSource {
    func contactModels(for contactPickerView: MBContactPicker!) -> [Any]! {
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
    
    func selectedContactModels(for contactPickerView: MBContactPicker!) -> [Any]! {
        return self.datasource?.composeViewSelectedContactsForPicker(self, picker: contactPickerView)
    }
}


// MARK: - MBContactPickerDelegate

extension ComposeView: MBContactPickerDelegate {
    func contactCollectionView(_ contactCollectionView: MBContactCollectionView!, didAddContact model: MBContactPickerModelProtocol!) {
        let contactPicker = contactPickerForContactCollectionView(contactCollectionView)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didAddContact: model as! ContactVO, toPicker: contactPicker)
    }
    
    func contactCollectionView(_ contactCollectionView: MBContactCollectionView!, didRemoveContact model: MBContactPickerModelProtocol!) {
        let contactPicker = contactPickerForContactCollectionView(contactCollectionView)
        self.notifyViewSize(true)
        self.delegate?.composeView(self, didRemoveContact: model as! ContactVO, fromPicker: contactPicker)
    }
    
    func contactPicker(_ contactPicker: MBContactPicker!, didEnterCustomText text: String!, needFocus focus: Bool) {
        let customContact = ContactVO(id: "", name: text, email: text)
        contactPicker.add(toSelectedContacts: customContact, needFocus: focus)
    }
    
    func contactPicker(_ contactPicker: MBContactPicker!, didUpdateContentHeightTo newHeight: CGFloat) {
        self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
    }
    
    func didShowFilteredContacts(for contactPicker: MBContactPicker!) {
        self.view.bringSubview(toFront: contactPicker)
        if (contactPicker.frame.size.height <= contactPicker.currentContentHeight) {
            let pickerRectInWindow = self.view.convert(contactPicker.frame, to: nil)
            let newHeight = self.view.window!.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight
            self.pickerHeight = newHeight
            self.updateContactPickerHeight(contactPicker, newHeight: newHeight)
        }
        
        if !contactPicker.isHidden {
            
        }
        
        self.notifyViewSize(false)
    }
    
    func didHideFilteredContacts(for contactPicker: MBContactPicker!) {
        self.view.sendSubview(toBack: contactPicker)
        if (contactPicker.frame.size.height > contactPicker.currentContentHeight) {
            self.updateContactPickerHeight(contactPicker, newHeight: contactPicker.currentContentHeight)
        }
        
        self.pickerHeight = 0;
        self.notifyViewSize(false)
    }
    
    // MARK: Private delegate helper methods
    
    fileprivate func contactPickerForContactCollectionView(_ contactCollectionView: MBContactCollectionView) -> MBContactPicker {
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
    internal func customFilterPredicate(_ searchString: String!) -> NSPredicate! {
        return NSPredicate(format: "contactTitle CONTAINS[cd] %@ or contactSubtitle CONTAINS[cd] %@", argumentArray: [searchString, searchString])
    }
}

// MARK: - UITextFieldDelegate
extension ComposeView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
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
        if let contacts = contactsSelected.value(forKey: ContactVO.Attributes.email) as? [String] {
            contactList = contacts.joined(separator: ",")
        }
        return contactList
    }
    
    var hasOutsideEmails: Bool {
        let contactsSelected = NSArray(array: self.contactsSelected)
        if let contacts = contactsSelected.value(forKey: ContactVO.Attributes.email) as? [String] {
            for contact in contacts {
                if contact.lowercased().range(of: "@protonmail.ch") == nil && contact.lowercased().range(of: "@protonmail.com") == nil {
                    return true
                }
            }
        }
        return false
    }
}

