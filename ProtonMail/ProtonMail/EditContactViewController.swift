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

class EditContactViewController: ProtonMailViewController {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    
    var contact: ContactVO!
    
    fileprivate let kInvalidEmailShakeTimes: Float = 3.0
    fileprivate let kInvalidEmailShakeOffset: CGFloat = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UITextField.appearance().tintColor = UIColor.ProtonMail.Gray_999DA1
        
        nameTextField.delegate = self
        emailTextField.delegate = self
        
        if (contact != nil) {
            nameTextField.text = contact.name
            emailTextField.text = contact.email
            self.title = NSLocalizedString("Edit Contact", comment: "edit contact navigation title")
        }
    }
    
    @IBAction func didTapCancelButton(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSaveButton(_ sender: UIBarButtonItem) {
        let name: String = (nameTextField.text ?? "").trim()
        let email: String = (emailTextField.text ?? "").trim()
        
        if (!email.isValidEmail()) {
            showInvalidEmailError()
        } else {
            ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
            
            if (contact == nil) {
                sharedContactDataService.addContact(name: name, email: email) { (contacts: [Contact]?, error: NSError?) in
                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                sharedContactDataService.updateContact(contactID: contact.contactId, name: name, email: email, completion: { ( contacts: [Contact]?, error: NSError?) -> Void in
                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
    
    func dismissKeyboard() {
        
        nameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        
    }
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
    
    fileprivate func showInvalidEmailError() {
        emailTextField.layer.borderColor = UIColor.red.cgColor
        emailTextField.layer.borderWidth = 0.5
        emailTextField.shake(kInvalidEmailShakeTimes, offset: kInvalidEmailShakeOffset)
    }
}

extension EditContactViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == nameTextField) {
            textField.resignFirstResponder()
            emailTextField.becomeFirstResponder()
        }
        if (textField == emailTextField) {
            emailTextField.resignFirstResponder()
        }
        return true
    }
}
