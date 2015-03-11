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

class ComposeViewController: ProtonMailViewController {

    private struct EncryptionStep {
        static let DefinePassword = "DefinePassword"
        static let ConfirmPassword = "ConfirmPassword"
        static let DefineHintPassword = "DefineHintPassword"
    }
    
    // MARK: - Private attributes
    
    private var contacts: [ContactVO]! = [ContactVO]()
    private var composeView: ComposeView!
    private var actualEncryptionStep = EncryptionStep.DefinePassword
    private var encryptionPassword: String!
    private var encryptionConfirmPassword: String!
    private var encryptionPasswordHint: String!
    
    // MARK: - View Controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.composeView = self.view as? ComposeView
        
        let contactExample: [Dictionary<String, String>] = [
            ["Id" : "1", "Name" : "Diego Santiviago", "Email" : "diego.santiviago@arctouch.com"],
            ["Id" : "2", "Name" : "Diego Santiviago 1", "Email" : "diego1.santiviago@arctouch.com"],
            ["Id" : "3", "Name" : "Diego Santiviago 2", "Email" : "diego2.santiviago@arctouch.com"],
            ["Id" : "4", "Name" : "Diego Santiviago 3", "Email" : "diego3.santiviago@arctouch.com"],
            ["Id" : "5", "Name" : "Diego Santiviago 4", "Email" : "diego4.santiviago@arctouch.com"],
            ["Id" : "6", "Name" : "Diego Santiviago 5", "Email" : "diego5.santiviago@arctouch.com"],
            ["Id" : "7", "Name" : "Eric Chamberlain", "Email" : "eric.chamberlain@arctouch.com"]
        ]
        
        for contact in contactExample {
            let id = contact["Id"]
            let name = contact["Name"]
            let email = contact["Email"]
            let isProtonMailContact = false
            
            contacts.append(ContactVO(id: id, name: name, email: email, isProtonMailContact: isProtonMailContact))
        }
        
        self.composeView.datasource = self
        self.composeView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.composeView.contactPicker.becomeFirstResponder()
    }
    
    
    // MARK: - ProtonMail View Controller
    
    override func shouldShowSideMenu() -> Bool {
        return false
    }
}

extension ComposeViewController: ComposeViewDelegate {
    func composeViewDidTapCancelButton(composeView: ComposeView) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func composeViewDidTapSendButton(composeView: ComposeView) {
        println("Did tap send button")
    }
    
    func composeViewDidTapEncryptedButton(composeView: ComposeView) {
        self.actualEncryptionStep = EncryptionStep.DefinePassword
        self.composeView.showDefinePasswordView()
        self.composeView.hidePasswordAndConfirmDoesntMatch()
    }
    
    func composeViewDidTapNextButton(composeView: ComposeView) {
        switch(actualEncryptionStep) {
        case EncryptionStep.DefinePassword:
            self.encryptionPassword = composeView.encryptedPasswordTextField.text
            self.actualEncryptionStep = EncryptionStep.ConfirmPassword
            self.composeView.showConfirmPasswordView()
            
        case EncryptionStep.ConfirmPassword:
            self.encryptionConfirmPassword = composeView.encryptedPasswordTextField.text
            
            if (self.encryptionPassword == self.encryptionConfirmPassword) {
                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
                self.composeView.hidePasswordAndConfirmDoesntMatch()
                self.composeView.showPasswordHintView()
            } else {
                self.composeView.showPasswordAndConfirmDoesntMatch()
            }
            
        case EncryptionStep.DefineHintPassword:
            self.encryptionPasswordHint = composeView.encryptedPasswordTextField.text
            self.actualEncryptionStep = EncryptionStep.DefinePassword
            self.composeView.showEncryptionDone()
        default:
            println("No step defined.")
        }
    }
    
    func composeViewDidTapAttachmentButton(composeView: ComposeView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Photo Library"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            let picker: UIImagePickerController = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(picker, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Take a Photo"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
                let picker: UIImagePickerController = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = UIImagePickerControllerSourceType.Camera
                self.presentViewController(picker, animated: true, completion: nil)
            }
        }))

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
}

extension ComposeViewController: ComposeViewDatasource {
    func composeViewContactsModel(composeView: ComposeView) -> [AnyObject]! {
        return contacts
    }
    
    func composeViewSelectedContacts(composeView: ComposeView) ->  [AnyObject]! {
        return []
    }
}

extension ComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        println("UIImagePickerControllerDelegate didFinishPickingImage")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
    }
}