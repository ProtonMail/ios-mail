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

enum ContactDetailSectionType: Int {
    case phone = 0
    case email = 1
}

class ContactDetailViewController: ProtonMailViewController {
    
    var contact: ContactVO!
    
    private let kInvalidEmailShakeTimes: Float = 3.0
    private let kInvalidEmailShakeOffset: CGFloat = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UITextField.appearance().tintColor = UIColor.ProtonMail.Gray_999DA1
        
//        nameTextField.delegate = self
//        emailTextField.delegate = self
//        
//        if (contact != nil) {
//            nameTextField.text = contact.name
//            emailTextField.text = contact.email
//            self.title = NSLocalizedString("Edit Contact")
//        }
    }
    
    @IBAction func didTapCancelButton(sender: UIBarButtonItem) {
        dismissKeyboard()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didTapSaveButton(sender: UIBarButtonItem) {
//        let name: String = (nameTextField.text ?? "").trim()
//        let email: String = (emailTextField.text ?? "").trim()
//        
//        if (!email.isValidEmail()) {
//            showInvalidEmailError()
//        } else {
//            ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
//            
//            if (contact == nil) {
//                sharedContactDataService.addContact(name: name, email: email) { (contacts: [Contact]?, error: NSError?) in
//                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
//                    self.dismissViewControllerAnimated(true, completion: nil)
//                }
//            } else {
//                sharedContactDataService.updateContact(contactID: contact.contactId, name: name, email: email, completion: { ( contacts: [Contact]?, error: NSError?) -> Void in
//                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
//                    self.dismissViewControllerAnimated(true, completion: nil)
//                })
//            }
//        }
    }
    
    func dismissKeyboard() {
        
//        nameTextField.resignFirstResponder()
//        emailTextField.resignFirstResponder()
        
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    private func showInvalidEmailError() {
//        emailTextField.layer.borderColor = UIColor.redColor().CGColor
//        emailTextField.layer.borderWidth = 0.5
//        emailTextField.shake(kInvalidEmailShakeTimes, offset: kInvalidEmailShakeOffset)
    }
}

extension ContactDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        if (textField == nameTextField) {
//            textField.resignFirstResponder()
//            emailTextField.becomeFirstResponder()
//        }
//        if (textField == emailTextField) {
//            emailTextField.resignFirstResponder()
//        }
        return true
    }
}



// MARK: - UITableViewDataSource

extension ContactDetailViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("contacts_email_cell", forIndexPath: indexPath) //as! UITableViewCell
        
//        var contact: ContactVO
//        
//        if (self.searchController.active) {
//            contact = searchResults[indexPath.row]
//        } else {
//            contact = contacts[indexPath.row]
//        }
//        
//        cell.contactEmailLabel.text = contact.email
//        cell.contactNameLabel.text = contact.name
//        
//        // temporary solution to show the icon
//        if (contact.isProtonMailContact) {
//            cell.contactSourceImageView.image = kProtonMailImage
//        } else {
//            cell.contactSourceImageView.hidden = true
//        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContactDetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Contact Details"
        } else {
            return "Encrypted Contact Details"
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            
        }
        
        let editClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            
        }
        
        let deleteAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Delete"), handler: deleteClosure)
        let editAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("Edit"), handler: editClosure)
        
        return [deleteAction, editAction]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }
}

