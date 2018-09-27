//
//  ComposeViewHeader.swift
//  ProtonMail - Created on 10/4/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation


protocol ComposeViewHeaderDelegate: AnyObject {
    func composeViewWillPresentSubview()
    func composeViewWillDismissSubview()

    func ComposeViewDidSizeChanged(_ size: CGSize, showPicker: Bool)
    func ComposeViewDidOffsetChanged(_ offset: CGPoint)
    func composeViewDidTapNextButton(_ composeView: ComposeViewHeader)
    func composeViewDidTapEncryptedButton(_ composeView: ComposeViewHeader)
    func composeViewDidTapAttachmentButton(_ composeView: ComposeViewHeader)

    func composeView(_ composeView: ComposeViewHeader, didAddContact contact: ContactPickerModelProtocol, toPicker picker: ContactPicker)
    func composeView(_ composeView: ComposeViewHeader, didRemoveContact contact: ContactPickerModelProtocol, fromPicker picker: ContactPicker)

    func composeViewHideExpirationView(_ composeView: ComposeViewHeader)
    func composeViewCancelExpirationData(_ composeView: ComposeViewHeader)
    func composeViewDidTapExpirationButton(_ composeView: ComposeViewHeader)
    func composeViewCollectExpirationData(_ composeView: ComposeViewHeader)

    func composeViewPickFrom(_ composeView: ComposeViewHeader)

    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
}

protocol ComposeViewHeaderDataSource: AnyObject {
    func composeViewContactsModelForPicker(_ composeView: ComposeViewHeader, picker: ContactPicker) -> [ContactPickerModelProtocol]
    func composeViewSelectedContactsForPicker(_ composeView: ComposeViewHeader, picker: ContactPicker) -> [ContactPickerModelProtocol]
}

/// NOTES:: somehow. if add two pickers only the first one could response the actions
class ComposeViewHeader: PMView {
    
    /// Mark : Override
    override func getNibName() -> String {
        return "ComposeViewHeader"
    }
    
    //
    // MARK: - Delegate and Datasource
    weak var datasource: ComposeViewHeaderDataSource?
    weak var delegate: ComposeViewHeaderDelegate?
    
    // MARK: - From field
    @IBOutlet weak var fromAddress: UILabel!
    @IBOutlet weak var fromPickerButton: UIButton!
    @IBOutlet weak var fromLable: UILabel!
    
    @IBOutlet weak var contentStackview: UIStackView!
    @IBOutlet weak var showCCButton: UIButton!

    @IBOutlet weak var ccStackview: UIStackView!
    @IBOutlet weak var bccStackview: UIStackView!
    
    /// MARK : -  subjectField
    @IBOutlet var subjectField: UITextField!
    
    /// MARK: - Action Buttons
    //    @IBOutlet weak var buttonView: UIView!
    @IBOutlet var encryptedButton: UIButton!
    @IBOutlet var expirationButton: UIButton!
    @IBOutlet var attachmentButton: UIButton!
    
    ///
    @IBOutlet weak var toPicker: ContactPicker!
    var toContacts: String {
        return toPicker.contactList
    }
    @IBOutlet weak var ccPicker: ContactPicker!
    var ccContacts: String {
        return ccPicker.contactList
    }
    @IBOutlet weak var bccPicker: ContactPicker!
    var bccContacts: String {
        return bccPicker.contactList
    }
    
    //    fileprivate var confirmExpirationButton: UIButton!
    //
    //    // MARK: - Encryption password
    //    @IBOutlet weak var passwordView: UIView!
    //    @IBOutlet var encryptedPasswordTextField: UITextField!
    //    @IBOutlet var encryptedActionButton: UIButton!
    //
    //
    //    // MARK: - Expiration Date
    //    @IBOutlet var expirationView: UIView!
    //    @IBOutlet var expirationDateTextField: UITextField!
    //

    //
    //    var selfView : UIView!
    //
    //    // MARK: - Constants
    fileprivate let kDefaultRecipientHeight : Int = 44
    //    fileprivate let kErrorMessageHeight: CGFloat = 48.0
    //    fileprivate let kNumberOfColumnsInTimePicker: Int = 2
    //    fileprivate let kNumberOfDaysInTimePicker: Int = 30
    //    fileprivate let kNumberOfHoursInTimePicker: Int = 24
    //    fileprivate let kCcBccContainerViewHeight: CGFloat = 96.0
    //
    //    //
    //
    //
    //    //
    //    fileprivate var errorView: ComposeErrorView!
    //    fileprivate var hasExpirationSchedule: Bool = false
    
    ///
    fileprivate let kAnimationDuration = 0.25
    fileprivate var isShowingCcBccView: Bool = false
    
    
    override func setup() {
        self.fromLable.text = LocalString._composer_from_label
        self.subjectField.placeholder = LocalString._composer_subject_placeholder
        
        self.configureContactPickerTemplate()
        
        self.toPicker.translatesAutoresizingMaskIntoConstraints = true
        self.toPicker.cellHeight = self.kDefaultRecipientHeight;
        self.toPicker.datasource = self
        self.toPicker.delegate = self
        
        self.ccPicker.translatesAutoresizingMaskIntoConstraints = true
        self.ccPicker.cellHeight = self.kDefaultRecipientHeight;
        self.ccPicker.datasource = self
        self.ccPicker.delegate = self
        
        self.bccPicker.translatesAutoresizingMaskIntoConstraints = true
        self.bccPicker.cellHeight = self.kDefaultRecipientHeight;
        self.bccPicker.datasource = self
        self.bccPicker.delegate = self
        self.bringSubviewToFront(bccPicker)
        
        //        self.encryptedPasswordTextField.placeholder = LocalString._composer_define_expiration_placeholder


//        self.configureEncryptionPasswordField()
//        self.configureExpirationField()
//        self.configureErrorMessage()
        
        delay(3.0) {
            self.ccPicker.becomeFirstResponder()
        }
    }
    
    override var intrinsicContentSize : CGSize {
        let sf = contentStackview.sizeThatFits(CGSize.zero)
        return sf
    }
    
    @IBAction func plusButtonAction(_ sender: Any) {
        self.plusButtonHandle()
    }
    
    private func plusButtonHandle() {
        UIView.animate(withDuration: self.kAnimationDuration) {
            if (self.isShowingCcBccView) {
                self.ccStackview.isHidden = true
                self.bccStackview.isHidden = true
                self.showCCButton.setImage(UIImage(named: "compose_pluscontact"), for:UIControl.State() )
            } else {
                self.ccStackview.isHidden = false
                self.bccStackview.isHidden = false
                self.showCCButton.setImage(UIImage(named: "compose_minuscontact"), for:UIControl.State() )
            }
            self.isShowingCcBccView = !self.isShowingCcBccView
        }
    }
    
    func reloadData() {
        self.toPicker.reloadData()
        self.ccPicker.reloadData()
        self.bccPicker.reloadData()
    }
    
    func reloadPicker() {
        self.toPicker.reload()
        self.ccPicker.reload()
        self.bccPicker.reload()
    }
    
    func dismissKeyboard() {
        self.subjectField.becomeFirstResponder()
        self.subjectField.resignFirstResponder()
    }
    
    var hasOutSideEmails : Bool {
        let toHas = toPicker.hasOutsideEmails
        if (toHas) {
            return true;
        }
        
        let ccHas = ccPicker.hasOutsideEmails
        if (ccHas) {
            return true;
        }
        
        let bccHas = bccPicker.hasOutsideEmails
        if (bccHas) {
            return true;
        }
        
        return false
    }

    var hasNonePMEmails : Bool {
        let toHas = toPicker.hasNonePM
        if (toHas) {
            return true;
        }

        let ccHas = ccPicker.hasNonePM
        if (ccHas) {
            return true;
        }

        let bccHas = bccPicker.hasNonePM
        if (bccHas) {
            return true;
        }

        return false
    }


    var hasPGPPinned : Bool {
        let toHas = toPicker.hasPGPPinned
        if (toHas) {
            return true;
        }

        let ccHas = ccPicker.hasPGPPinned
        if (ccHas) {
            return true;
        }

        let bccHas = bccPicker.hasPGPPinned
        if (bccHas) {
            return true;
        }

        return false
    }

    var nonePMEmails : [String] {
        var out : [String] = [String]()
        out.append(contentsOf: toPicker.nonePMEmails)
        out.append(contentsOf: ccPicker.nonePMEmails)
        out.append(contentsOf: bccPicker.nonePMEmails)
        return out
    }

    var pgpEmails : [String] {
        var out : [String] = [String]()
        out.append(contentsOf: toPicker.pgpEmails)
        out.append(contentsOf: ccPicker.pgpEmails)
        out.append(contentsOf: bccPicker.pgpEmails)
        return out
    }

    var allEmails : String {  // email,email,email
        var emails : [String] = []

        let toEmails = toPicker.contactList
        if !toEmails.isEmpty  {
            emails.append(toEmails)
        }

        let ccEmails = ccPicker.contactList
        if !ccEmails.isEmpty  {
            emails.append(ccEmails)
        }

        let bccEmails = bccPicker.contactList
        if !bccEmails.isEmpty  {
            emails.append(bccEmails)
        }
        if emails.isEmpty {
            return ""
        }
        return emails.joined(separator: ",")
    }

//    var expirationTimeInterval: TimeInterval = 0
//
//    var hasContent: Bool {//need check body also here
//        return !toContacts.isEmpty || !ccContacts.isEmpty || !bccContacts.isEmpty || !subjectTitle.isEmpty
//    }

    func set(subject : String) {
        self.subjectField.text = subject
    }
    
    var subject : String {
        get {
            return self.subjectField.text ?? ""
        }
    }

    func set(from email: String, picker isEnabled : Bool) {
        self.fromAddress.text = email
        self.fromPickerButton.isEnabled = isEnabled
    }
    
//    @IBAction func fromPickerAction(_ sender: AnyObject) {
//        self.delegate?.composeViewPickFrom(self)
//    }

//    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
//        self.hidePasswordAndConfirmDoesntMatch()
//        self.view.endEditing(true)
//        self.delegate?.composeViewDidTapAttachmentButton(self)
//    }
//
    func update(attIcon hasAtts: Bool) {
        if hasAtts {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment-active"), for: UIControl.State())
        } else {
            self.attachmentButton.setImage(UIImage(named: "compose_attachment"), for: UIControl.State())
        }
    }

//    @IBAction func expirationButtonTapped(_ sender: UIButton) {
//        self.hidePasswordAndConfirmDoesntMatch()
//        self.view.endEditing(true)
//        let _ = self.toContactPicker.becomeFirstResponder()
//        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
//            self.passwordView.alpha = 0.0
//            self.buttonView.alpha = 0.0
//            self.expirationView.alpha = 1.0
//
//            self.toContactPicker.isUserInteractionEnabled = false
//            self.ccContactPicker.isUserInteractionEnabled = false
//            self.bccContactPicker.isUserInteractionEnabled = false
//            self.subject.isUserInteractionEnabled = false
//
//            self.showExpirationPicker()
//            let _ = self.toContactPicker.resignFirstResponder()
//        })
//    }
//
//    @IBAction func encryptedButtonTapped(_ sender: UIButton) {
//        self.hidePasswordAndConfirmDoesntMatch()
//        self.delegate?.composeViewDidTapEncryptedButton(self)
//    }
//
//    @IBAction func didTapExpirationDismissButton(_ sender: UIButton) {
//        self.hideExpirationPicker()
//    }
//
//    @IBAction func didTapEncryptedDismissButton(_ sender: UIButton) {
//        self.delegate?.composeViewDidTapEncryptedButton(self)
//        self.encryptedPasswordTextField.resignFirstResponder()
//        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
//            self.encryptedPasswordTextField.text = ""
//            self.passwordView.alpha = 0.0
//            self.buttonView.alpha = 1.0
//        })
//    }
//
//
//    // Mark: -- Private Methods
//    fileprivate func includeButtonBorder(_ view: UIView) {
//        view.layer.borderWidth = 1.0
//        view.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.cgColor
//    }
//
//    fileprivate func configureEncryptionPasswordField() {
//        let passwordLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: self.encryptedPasswordTextField.frame.size.height))
//        encryptedPasswordTextField.leftView = passwordLeftPaddingView
//        encryptedPasswordTextField.leftViewMode = UITextField.ViewMode.always
//
//        let nextButton = UIButton()
//        nextButton.addTarget(self, action: #selector(ComposeView.didTapNextButton), for: UIControl.Event.touchUpInside)
//        nextButton.setImage(UIImage(named: "next"), for: UIControl.State())
//        nextButton.sizeToFit()
//
//        let nextView = UIView(frame: CGRect(x: 0, y: 0, width: nextButton.frame.size.width + 10, height: nextButton.frame.size.height))
//        nextView.addSubview(nextButton)
//        encryptedPasswordTextField.rightView = nextView
//        encryptedPasswordTextField.rightViewMode = UITextField.ViewMode.always
//    }
//
//    fileprivate func configureExpirationField() {
//        let expirationLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: self.expirationDateTextField.frame.size.height))
//        expirationDateTextField.leftView = expirationLeftPaddingView
//        expirationDateTextField.leftViewMode = UITextField.ViewMode.always
//
//        self.confirmExpirationButton = UIButton()
//        confirmExpirationButton.addTarget(self, action: #selector(ComposeView.didTapConfirmExpirationButton), for: UIControl.Event.touchUpInside)
//        confirmExpirationButton.setImage(UIImage(named: "next"), for: UIControl.State())
//        confirmExpirationButton.sizeToFit()
//
//        let confirmView = UIView(frame: CGRect(x: 0, y: 0, width: confirmExpirationButton.frame.size.width + 10, height: confirmExpirationButton.frame.size.height))
//        confirmView.addSubview(confirmExpirationButton)
//        expirationDateTextField.rightView = confirmView
//        expirationDateTextField.rightViewMode = UITextField.ViewMode.always
//        expirationDateTextField.delegate = self
//    }
//
//    fileprivate func configureErrorMessage() {
//        self.errorView = ComposeErrorView()
//        self.errorView.backgroundColor = UIColor.white
//        self.errorView.clipsToBounds = true
//        self.errorView.backgroundColor = UIColor.darkGray
//        self.view.addSubview(errorView)
//    }
    
    fileprivate func configureContactPickerTemplate() {
        ContactCollectionViewContactCell.appearance().tintColor = UIColor.ProtonMail.Blue_6789AB
        ContactCollectionViewContactCell.appearance().font = Fonts.h6.light
        ContactCollectionViewPromptCell.appearance().font = Fonts.h6.light
        ContactCollectionViewEntryCell.appearance().font = Fonts.h6.light
    }
//
//    ///
//    internal func notifyViewSize(_ animation : Bool) {
//        UIView.animate(withDuration: animation ? self.kAnimationDuration : 0, delay:0, options: UIView.AnimationOptions(), animations: {
//            self.updateViewSize()
//            let size = CGSize(width: self.view.frame.width, height: self.passwordView.frame.origin.y + self.passwordView.frame.height + self.pickerHeight)
//            self.delegate?.ComposeViewDidSizeChanged(size, showPicker: self.pickerHeight > 0.0)
//        }, completion: nil)
//    }


//    @objc internal func didTapConfirmExpirationButton() {
//        self.delegate?.composeViewCollectExpirationData(self)
//    }
//
//    @objc internal func didTapNextButton() {
//        self.delegate?.composeViewDidTapNextButton(self)
//    }
//
//
//    internal func showConfirmPasswordView() {
//        self.encryptedPasswordTextField.placeholder = LocalString._composer_eo_confirm_pwd_placeholder
//        self.encryptedPasswordTextField.isSecureTextEntry = true
//        self.encryptedPasswordTextField.text = ""
//    }
//
//    internal func showPasswordHintView() {
//        self.encryptedPasswordTextField.placeholder = LocalString._define_hint_optional
//        self.encryptedPasswordTextField.isSecureTextEntry = false
//        self.encryptedPasswordTextField.text = ""
//    }
//
//    internal func showEncryptionDone() {
//        didTapEncryptedDismissButton(encryptedButton)
//        self.encryptedPasswordTextField.placeholder = LocalString._composer_define_password
//        self.encryptedPasswordTextField.isSecureTextEntry = true
//        self.encryptedButton.setImage(UIImage(named: "compose_lock-active"), for: UIControl.State())
//    }
//
//    internal func showEncryptionRemoved() {
//        didTapEncryptedDismissButton(encryptedButton)
//        self.encryptedButton.setImage(UIImage(named: "compose_lock"), for: UIControl.State())
//    }
//
//    internal func showExpirationPicker() {
//        UIView.animate(withDuration: 0.2, animations: { () -> Void in
//            self.delegate?.composeViewDidTapExpirationButton(self)
//        })
//    }
//
//    internal func hideExpirationPicker() {
//        self.toContactPicker.isUserInteractionEnabled = true
//        self.ccContactPicker.isUserInteractionEnabled = true
//        self.bccContactPicker.isUserInteractionEnabled = true
//        self.subject.isUserInteractionEnabled = true
//        //self.htmlEditor.view.userInteractionEnabled = true
//
//        UIView.animate(withDuration: self.kAnimationDuration, animations: { () -> Void in
//            self.expirationView.alpha = 0.0
//            self.buttonView.alpha = 1.0
//            self.delegate?.composeViewHideExpirationView(self)
//        })
//    }
//
//    internal func showPasswordAndConfirmDoesntMatch(_ error : String) {
//        self.errorView.backgroundColor = UIColor.ProtonMail.Red_FF5959
//
//        self.errorView.mas_updateConstraints { (update) -> Void in
//            update?.removeExisting = true
//            let _ = update?.left.equalTo()(self.selfView)
//            let _ = update?.right.equalTo()(self.selfView)
//            let _ = update?.height.equalTo()(self.kErrorMessageHeight)
//            let _ = update?.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
//        }
//
//        self.errorView.setError(error, withShake: true)
//
//        UIView.animate(withDuration: 0.1, animations: { () -> Void in
//
//        })
//    }
//
//    internal func hidePasswordAndConfirmDoesntMatch() {
//        self.errorView.mas_updateConstraints { (update) -> Void in
//            update?.removeExisting = true
//            let _ = update?.left.equalTo()(self.view)
//            let _ = update?.right.equalTo()(self.view)
//            let _ = update?.height.equalTo()(0)
//            let _ = update?.top.equalTo()(self.encryptedPasswordTextField.mas_bottom)
//        }
//
//        UIView.animate(withDuration: 0.1, animations: { () -> Void in
//            //self.layoutIfNeeded()
//        })
//    }
//
//    func updateExpirationValue(_ intagerV : TimeInterval, text : String) {
//        self.expirationDateTextField.text = text
//        self.expirationTimeInterval = intagerV
//    }
//
//    func setExpirationValue (_ day : Int, hour : Int) -> Bool {
//        if (day == 0 && hour == 0 && !hasExpirationSchedule) {
//            self.expirationDateTextField.shake(3, offset: 10.0)
//
//            return false
//
//        } else {
//            if (!hasExpirationSchedule) {
//                self.expirationButton.setImage(UIImage(named: "compose_expiration-active"), for: UIControl.State())
//                self.confirmExpirationButton.setImage(UIImage(named: "compose_expiration_cancel"), for: UIControl.State())
//            } else {
//                self.expirationDateTextField.text = ""
//                self.expirationTimeInterval  = 0;
//                self.expirationButton.setImage(UIImage(named: "compose_expiration"), for: UIControl.State())
//                self.confirmExpirationButton.setImage(UIImage(named: "next"), for: UIControl.State())
//                self.delegate?.composeViewCancelExpirationData(self)
//
//            }
//            hasExpirationSchedule = !hasExpirationSchedule
//            self.hideExpirationPicker()
//            return true
//        }
//    }
}

// MARK: - ContactPickerDataSource
extension ComposeViewHeader: ContactPickerDataSource {
    
    func picker(contactPicker: ContactPicker, model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?) {
        self.delegate?.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    func contactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol] {
        if (contactPickerView == toPicker) {
            contactPickerView.prompt = LocalString._composer_to_label
        } else if (contactPickerView == ccPicker) {
            contactPickerView.prompt = LocalString._composer_cc_label
        } else if (contactPickerView == bccPicker) {
            contactPickerView.prompt = LocalString._composer_bcc_label
        }
        return self.datasource?.composeViewContactsModelForPicker(self, picker: contactPickerView) ?? [ContactPickerModelProtocol]()
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: ContactPicker) -> [ContactPickerModelProtocol] {
        return self.datasource?.composeViewSelectedContactsForPicker(self, picker: contactPickerView) ?? [ContactPickerModelProtocol]()
    }
}


// MARK: - ContactPickerDelegate
extension ComposeViewHeader: ContactPickerDelegate {
    func contactPicker(contactPicker: ContactPicker, didUpdateContentHeightTo newHeight: CGFloat) {
        
        UIView.animate(withDuration: self.kAnimationDuration) {
            contactPicker.frame.size.height = newHeight
            self.layoutIfNeeded()
            self.delegate?.ComposeViewDidOffsetChanged(CGPoint.zero)
        }
        //self.updateContactPickerHeight(contactPicker, newHeight: newHeight)1
    }
    
    func didShowFilteredContactsForContactPicker(contactPicker: ContactPicker) {
        self.delegate?.composeViewWillPresentSubview()
    }
    
    func didHideFilteredContactsForContactPicker(contactPicker: ContactPicker) {
        self.delegate?.composeViewWillDismissSubview()
//        self.view.sendSubviewToBack(contactPicker)
//        if (contactPicker.frame.size.height > contactPicker.currentContentHeight) {
//            self.updateContactPickerHeight(contactPicker, newHeight: contactPicker.currentContentHeight)
//        }
//        self.pickerHeight = 0;
//        self.notifyViewSize(false)
    }
    
    func contactPicker(contactPicker: ContactPicker, didEnterCustomText text: String, needFocus focus: Bool) {
        let customContact = ContactVO(id: "", name: text, email: text)
        contactPicker.addToSelectedContacts(model: customContact, needFocus: focus)
    }
    
    func contactPicker(picker: ContactPicker, pasted text: String, needFocus focus: Bool) {
        if text.contains(check: ",") {
            let cusTexts = text.split(separator: ",")
            for cusText in cusTexts {
                let trimmed = cusText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let customContact = ContactVO(id: "", name: trimmed, email: trimmed)
                    picker.addToSelectedContacts(model: customContact, needFocus: focus)
                }
            }
        } else if text.contains(check: ";") {
            let cusTexts = text.split(separator: ";")
            for cusText in cusTexts {
                let trimmed = cusText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let customContact = ContactVO(id: "", name: trimmed, email: trimmed)
                    picker.addToSelectedContacts(model: customContact, needFocus: focus)
                }
            }
        } else {
            let customContact = ContactVO(id: "", name: text, email: text)
            picker.addToSelectedContacts(model: customContact, needFocus: focus)
        }
    }
    
    func useCustomFilter() -> Bool {
        return true
    }
    
    func customFilterPredicate(searchString: String) -> NSPredicate {
        return NSPredicate(format: "contactTitle CONTAINS[cd] %@ or contactSubtitle CONTAINS[cd] %@", argumentArray: [searchString, searchString])
    }
    
    func collectionView(at: UICollectionView?, willChangeContentSizeTo newSize: CGSize) {
   
    }
    
    func collectionView(at: ContactCollectionView, entryTextDidChange text: String) {
        
    }
    
    func collectionView(at: ContactCollectionView, didEnterCustom text: String, needFocus focus: Bool) {
        
    }
    
    func collectionView(at: ContactCollectionView, didSelect contact: ContactPickerModelProtocol) {
        
    }
    
    func collectionView(at: ContactCollectionView, didAdd contact: ContactPickerModelProtocol) {
        let contactPicker = contactPickerForContactCollectionView(at)
//        self.notifyViewSize(true)
        self.delegate?.composeView(self, didAddContact: contact, toPicker: contactPicker)
    }
    
    func collectionView(at: ContactCollectionView, didRemove contact: ContactPickerModelProtocol) {
        let contactPicker = contactPickerForContactCollectionView(at)
//        self.notifyViewSize(true)
        self.delegate?.composeView(self, didRemoveContact: contact, fromPicker: contactPicker)
    }
    
    func collectionView(at: ContactCollectionView, pasted text: String, needFocus focus: Bool) {
        
    }
    
    func collectionContactCell(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?) {
        self.delegate?.lockerCheck(model: model, progress: progress, complete: complete)
    }
    
    // MARK: Private delegate helper methods
    fileprivate func contactPickerForContactCollectionView(_ contactCollectionView: ContactCollectionView) -> ContactPicker {
        var contactPicker: ContactPicker = toPicker
        if (contactCollectionView == toPicker.contactCollectionView) {
            contactPicker = toPicker
        } else if (contactCollectionView == ccPicker.contactCollectionView) {
            contactPicker = ccPicker
        } else if (contactCollectionView == bccPicker.contactCollectionView) {
            contactPicker = bccPicker
        }
        return contactPicker
    }
}
