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

class ContactsViewController: ProtonMailViewController {
    
    
    // Temporary class, just to bind the temporary array.
    
    class Contact: NSObject, MBContactPickerModelProtocol {
        var contactTitle: String!
        var contactSubtitle: String!
        
        init(name: String!, email: String!) {
            self.contactTitle = name
            self.contactSubtitle = email
        }
    }
    
    
    // MARK: - Private attributes
    
    private var contacts: [Contact]! = [Contact]()
    
    
    // MARK: - View Outlets
    
    @IBOutlet var contactPickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var contactPicker: MBContactPicker!
    
    
    // MARK: - View Controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contactExample: [Dictionary<String, String>] = [
            ["Name" : "Diego Santiviago", "Email" : "diego.santiviago@arctouch.com"],
            ["Name" : "Eric Chamberlain", "Email" : "eric.chamberlain@arctouch.com"]
        ]
        
        for contact in contactExample {
            let name = contact["Name"]
            let email = contact["Email"]
            contacts.append(Contact(name: name, email: email))
        }
        
        contactPicker.datasource = self
        contactPicker.delegate = self
    }
    
    
    // MARK: - Private Methods
    
    private func updateContactPickerHeight(newHeight: CGFloat) {
        self.contactPickerHeightConstraint.constant = newHeight
        
        UIView.animateWithDuration(NSTimeInterval(contactPicker.animationSpeed), animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
}


// MARK: - MBContactPickerDataSource

extension ContactsViewController: MBContactPickerDataSource {
    func contactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        return self.contacts
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        return []
    }
}


// MARK: - MBContactPickerDelegate

extension ContactsViewController: MBContactPickerDelegate {
    
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
        if (self.contactPickerHeightConstraint.constant <= contactPicker.currentContentHeight) {
            let pickerRectInWindow = self.view.convertRect(contactPicker.frame, fromView: nil)
            let newHeight = self.view.window!.bounds.size.height - pickerRectInWindow.origin.y - contactPicker.keyboardHeight
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