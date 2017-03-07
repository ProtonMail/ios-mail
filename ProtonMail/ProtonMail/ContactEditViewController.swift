//
//  ContactEditViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/6/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



class ContactEditViewController: ProtonMailViewController {
    
    //    @IBOutlet var nameTextField: UITextField!
    //    @IBOutlet var emailTextField: UITextField!
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

extension ContactEditViewController: UITextFieldDelegate {
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
