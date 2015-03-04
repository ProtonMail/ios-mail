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
}

protocol ComposeViewDatasource {
    func composeViewContactsModel(composeView: ComposeView) -> [AnyObject]!
    func composeViewSelectedContacts(composeView: ComposeView) -> [AnyObject]!
}

class ComposeView: UIView {
    
    
    // MARK: - Delegate and Datasource
    
    var datasource: ComposeViewDatasource?
    var delegate: ComposeViewDelegate?
    
    
    // MARK: - View Outlets
    
    @IBOutlet var contactPickerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contactPicker: MBContactPicker!
    @IBOutlet var subject: UITextField!
    @IBOutlet var encryptedButton: UIButton!
    @IBOutlet var expirationButton: UIButton!
    @IBOutlet var attachmentButton: UIButton!
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.configureContactPicketTemplate()
        self.includeButtonBorder(encryptedButton)
        self.includeButtonBorder(attachmentButton)
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.subject.addBorder(.Top, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        self.expirationButton.addBorder(.Top, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        self.expirationButton.addBorder(.Bottom, color: UIColor.ProtonMail.Gray_C9CED4, borderWidth: 1.0)
        
        self.contactPicker.datasource = self
        self.contactPicker.delegate = self
        
        let subjectPaddingView = UIView(frame: CGRectMake(0, 0, 12, self.subject.frame.size.height))
        subject.leftView = subjectPaddingView
        subject.leftViewMode = UITextFieldViewMode.Always
    }
    
    // MARK: - Private Methods
    
    private func includeButtonBorder(button: UIButton) {
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.CGColor
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
