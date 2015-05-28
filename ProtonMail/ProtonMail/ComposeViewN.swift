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
    

    func composeViewDidTapCancelButton(composeView: ComposeViewN)
    func composeViewDidTapSendButton(composeView: ComposeViewN)
    func composeViewDidTapNextButton(composeView: ComposeViewN)
    func composeViewDidTapEncryptedButton(composeView: ComposeViewN)
    func composeViewDidTapAttachmentButton(composeView: ComposeViewN)
    func composeView(composeView: ComposeViewN, didAddContact contact: ContactVO, toPicker picker: MBContactPicker)
    func composeView(composeView: ComposeViewN, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker)
    func composeViewDidSizeChanged(composeView: ComposeViewN, size: CGSize)
    
}

protocol ComposeViewNDataSource {
    func composeViewContactsModelForPicker(composeView: ComposeViewN, picker: MBContactPicker) -> [AnyObject]!
    func composeViewSelectedContactsForPicker(composeView: ComposeViewN, picker: MBContactPicker) -> [AnyObject]!
}

class ComposeViewN: UIViewController {
    
    var toContactPicker: MBContactPicker!
    var toContacts: String {
        return toContactPicker.contactList
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
    
    @IBOutlet var fakeContactPickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subject: UITextField!
    @IBOutlet var bodyTextView: UITextView!
    
    
    @IBOutlet var showCcBccButton: UIButton!


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
    
    private var errorView: UIView!
    private var errorTextView: UITextView!
    private var isShowingCcBccView: Bool = false
    private var hasExpirationSchedule: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.selfView = self.view;
        
        self.configureToContactPicker()
        self.configureCcContactPicker()
        self.configureBccContactPicker()

        self.view.bringSubviewToFront(showCcBccButton)
        self.view.bringSubviewToFront(subject);
        self.view.sendSubviewToBack(ccContactPicker)
        self.view.sendSubviewToBack(bccContactPicker)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func contactPlusButtonTapped(sender: UIButton) {
        self.plusButtonHandle();
    }
    
    
    ///
    internal func plusButtonHandle()
    {
        if (isShowingCcBccView) {
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight
            ccContactPicker.alpha = 0.0
            bccContactPicker.alpha = 0.0
            showCcBccButton.setImage(UIImage(named: "plus_compose"), forState:UIControlState.Normal )
        } else {
            ccContactPicker.alpha = 1.0
            bccContactPicker.alpha = 1.0
            fakeContactPickerHeightConstraint.constant = toContactPicker.currentContentHeight + ccContactPicker.currentContentHeight + bccContactPicker.currentContentHeight
            showCcBccButton.setImage(UIImage(named: "minus_compose"), forState:UIControlState.Normal )
        }
        
        isShowingCcBccView = !isShowingCcBccView
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
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
        
        self.delegate?.composeViewDidSizeChanged(self, size: CGSize(width: self.view.frame.width, height: newHeight + 100))
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

