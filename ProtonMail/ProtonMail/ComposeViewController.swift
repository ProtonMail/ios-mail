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

//class ComposeViewController: ProtonMailViewController {
//    private struct EncryptionStep {
//        static let DefinePassword = "DefinePassword"
//        static let ConfirmPassword = "ConfirmPassword"
//        static let DefineHintPassword = "DefineHintPassword"
//    }
//
//    let draftAction = "draft"
//    
//    // MARK: - Private attributes
//    
//    @IBOutlet weak var cancelButton: UIBarButtonItem!
//    
//    var attachments: [AnyObject]?
//    var message: Message?
//    var action: String?
//    
//    var toSelectedContacts: [ContactVO]! = [ContactVO]()
//    private var ccSelectedContacts: [ContactVO]! = [ContactVO]()
//    private var bccSelectedContacts: [ContactVO]! = [ContactVO]()
//    private var contacts: [ContactVO]! = [ContactVO]()
//    private var composeView: ComposeView!
//    private var actualEncryptionStep = EncryptionStep.DefinePassword
//    private var encryptionPassword: String = ""
//    private var encryptionConfirmPassword: String = ""
//    private var encryptionPasswordHint: String = ""
//    private var hasAccessToAddressBook: Bool = false
//
//    private var htmlEditor: HtmlEditorViewController!
//    
//    // MARK: - View Controller lifecycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.composeView = self.view as? ComposeView
//        self.composeView.datasource = self
//        self.composeView.delegate = self
//    
//        
//        handleMessage(message, action: action)
//        
//        if (self.toSelectedContacts.count == 0) {
//            self.composeView.toContactPicker.becomeFirstResponder()
//        } else {
//
//           // self.htmlEditor.focusTextEditor();
//            //self.composeView.bodyTextView.becomeFirstResponder()
//        }
//        
//        sharedContactDataService.fetchContactVOs { (contacts, error) -> Void in
//            if let error = error {
//                NSLog("\(__FUNCTION__) error: \(error)")
//                
//                let alertController = error.alertController()
//                alertController.addOKAction()
//                
//                self.presentViewController(alertController, animated: true, completion: nil)
//            }
//            
//            self.contacts = contacts
//            
//            self.composeView.toContactPicker.reloadData()
//            self.composeView.ccContactPicker.reloadData()
//            self.composeView.bccContactPicker.reloadData()
//        }
//        
//        if message != nil
//        {
//            message?.isRead = true;
//            if let error = message!.managedObjectContext?.saveUpstreamIfNeeded() {
//                NSLog("\(__FUNCTION__) error: \(error)")
//            }
//        }
//    }
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//    }
//    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        self.composeView.updateConstraintsIfNeeded()
//        if ccSelectedContacts.count > 0 {
//            composeView.plusButtonHandle()
//        }
//    }
//    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//
//        if (segue.identifier == "toHtmlEditor") {
//            htmlEditor = segue.destinationViewController as? HtmlEditorViewController;
//        }
//    }
//
//    
//    
//    // MARK: ProtonMail View Controller
//    override func shouldShowSideMenu() -> Bool {
//        return false
//    }
//    
//    // MARK: - Private methods
//    
//    private func handleMessage(message: Message?, action: String?) {
//        let signature = !sharedUserDataService.signature.isEmpty ? "\n\n\(sharedUserDataService.signature)" : ""
//        let htmlString = "<br><br><br><br>\(signature)<br><br>";
//        htmlEditor.setHTML(htmlString);
//        
//        if let message = message {
//            if let action = action {
//                if action == ComposeView.ComposeMessageAction.Reply || action == ComposeView.ComposeMessageAction.ReplyAll {
//                    composeView.subject.text = "Re: \(message.title)"
//                    toSelectedContacts.append(ContactVO(id: "", name: message.senderName, email: message.sender))
//                    
//                    let replyMessage = NSLocalizedString("Reply message")
//                    let body = message.decryptBodyIfNeeded(nil) ?? ""
//                    let time = message.time?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
//                    let replyHeader = time + ", " + message.senderName + " <'\(message.sender)'>"
//                    let sp = "<div>\(replyHeader) wrote:</div><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\"><tbody><tr><td align=\"center\" valign=\"top\"> <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:transparent;border-bottom:0;border-bottom:solid 1px #00929f\" width=\"600\"> "
//                    
//                    htmlEditor.setHTML("\(htmlString) \(sp) \(body)</blockquote>")
//
//                    if action == ComposeView.ComposeMessageAction.ReplyAll {
//                        updateSelectedContacts(&ccSelectedContacts, withNameList: message.ccNameList, emailList: message.ccList)
//                    }
//                } else if action == ComposeView.ComposeMessageAction.Forward {
//                    composeView.subject.text = "Fwd: \(message.title)"
//                    
//                    let time = message.time?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
//
//                    var forwardHeader = "<br><br><br>---------- Forwarded message ----------<br>From: \(message.senderName)<br>Date: \(time)<br>Subject: \(message.title)"
//                    if message.recipientList != "" {
//                        forwardHeader += "<br>To: \(message.recipientList)<br>"
//                    }
//                    if message.ccList != "" {
//                        forwardHeader += "<br>To: \(message.ccList)<br>"
//                    }
//                    forwardHeader += "<br><br><br>"
//
//                    
//                    let body = message.decryptBodyIfNeeded(nil) ?? ""
//                    
//                    htmlEditor.setHTML("<br><br><br>\(signature) \(forwardHeader) \(body)")
//                    
//                } else if action == draftAction {
//                    navigationItem.leftBarButtonItem = nil
//                    
//                    updateSelectedContacts(&toSelectedContacts, withNameList: message.recipientNameList, emailList: message.recipientList)
//                    updateSelectedContacts(&ccSelectedContacts, withNameList: message.ccNameList, emailList: message.ccList)
//                    updateSelectedContacts(&bccSelectedContacts, withNameList: message.bccNameList, emailList: message.bccList)
//                    
//                    composeView.subject.text = message.title
//                    
//                    if !message.attachments.isEmpty {
//                        attachments = []
//                    }
//                    
//                    for attachment in message.attachments.allObjects as! [Attachment] {
//                        if let fileData = attachment.fileData {
//                            attachments?.append(fileData)
//                        }
//                    }
//                    
//                    var error: NSError?
//                    htmlEditor.setHTML(message.decryptBodyIfNeeded(&error) ?? "")
//                    if error != nil {
//                        NSLog("\(__FUNCTION__) error: \(error)")
//                    }
//                }
//            }
//        }
//    }
//    
//    private func updateSelectedContacts(inout selectedContacts: [ContactVO]!, withNameList nameList: String, emailList: String) {
//        if selectedContacts == nil {
//            selectedContacts = []
//        }
//        
//        let emails = emailList.splitByComma()
//        var names = nameList.splitByComma()
//        
//        // this prevents a crash if there are less names than emails
//        if count(names) != count(emails) {
//            names = emails
//        }
//        
//        let nameCount = names.count
//        let emailCount = count(emails)
//        for var i = 0; i < emailCount; i++ {
//            selectedContacts.append(ContactVO(id: "", name: ((i>=0 && i<nameCount) ? names[i] : ""), email: emails[i]))
//        }
//    }
//}
//
//
//// MARK: - AttachmentsViewControllerDelegate
//extension ComposeViewController: AttachmentsViewControllerDelegate {
//    func attachmentsViewController(attachmentsViewController: AttachmentsViewController, didFinishPickingAttachments attachments: [AnyObject]) {
//        self.attachments = attachments
//    }
//}
//
//
//// MARK: - ComposeViewDelegate
//extension ComposeViewController: ComposeViewDelegate {
//    func composeViewDidTapCancelButton(composeView: ComposeView) {
//        let dismiss: (() -> Void) = {
//            if self.action == self.draftAction {
//                self.navigationController?.popViewControllerAnimated(true)
//            } else {
//                self.dismissViewControllerAnimated(true, completion: nil)
//            }
//        }
//        
//        if composeView.hasContent || ((attachments?.count ?? 0) > 0) {
//            let alertController = UIAlertController(title: NSLocalizedString("Confirmation"), message: nil, preferredStyle: .ActionSheet)
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft"), style: .Default, handler: { (action) -> Void in
//                sharedMessageDataService.saveDraft(
//                    recipientList: composeView.toContacts,
//                    bccList: composeView.bccContacts,
//                    ccList: composeView.ccContacts,
//                    title: composeView.subjectTitle,
//                    encryptionPassword: self.encryptionPassword,
//                    passwordHint: self.encryptionPasswordHint,
//                    expirationTimeInterval: composeView.expirationTimeInterval,
//                    body: self.htmlEditor.getHTML(),
//                    attachments: self.attachments)
//                
//                dismiss()
//            }))
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
//            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft"), style: .Destructive, handler: { (action) -> Void in
//                dismiss()
//            }))
//            
//            presentViewController(alertController, animated: true, completion: nil)
//        } else {
//            dismiss()
//        }
//    }
//    
//    func composeViewDidTapSendButton(composeView: ComposeView) {
//        sharedMessageDataService.send(
//            recipientList: composeView.toContacts,
//            bccList: composeView.bccContacts,
//            ccList: composeView.ccContacts,
//            title: composeView.subjectTitle,
//            encryptionPassword: encryptionPassword,
//            passwordHint: encryptionPasswordHint,
//            expirationTimeInterval: composeView.expirationTimeInterval,
//            body: self.htmlEditor.getHTML(),
//            attachments: attachments,
//            completion: {_, _, error in
//                if error == nil {
//                    if let message = self.message {
//                        println("MessageID after send:\(message.messageID)")
//                        println("Message Location : \(message.location )")
//                        if(message.messageID != "0" && message.location == MessageLocation.draft)
//                        {
//                            message.location = .trash
//                        }
//                        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
//                            NSLog("\(__FUNCTION__) error: \(error)")
//                        }
//                    }
//                }
//        })
//        
//        if presentingViewController != nil {
//            dismissViewControllerAnimated(true, completion: nil)
//        } else {
//            navigationController?.popViewControllerAnimated(true)
//        }
//    }
//
//    func composeViewDidTapEncryptedButton(composeView: ComposeView) {
//        self.actualEncryptionStep = EncryptionStep.DefinePassword
//        self.composeView.showDefinePasswordView()
//        self.composeView.hidePasswordAndConfirmDoesntMatch()
//    }
//    
//    func composeViewDidTapNextButton(composeView: ComposeView) {
//        switch(actualEncryptionStep) {
//        case EncryptionStep.DefinePassword:
//            self.encryptionPassword = composeView.encryptedPasswordTextField.text ?? ""
//            self.actualEncryptionStep = EncryptionStep.ConfirmPassword
//            self.composeView.showConfirmPasswordView()
//            
//        case EncryptionStep.ConfirmPassword:
//            self.encryptionConfirmPassword = composeView.encryptedPasswordTextField.text ?? ""
//            
//            if (self.encryptionPassword == self.encryptionConfirmPassword) {
//                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
//                self.composeView.hidePasswordAndConfirmDoesntMatch()
//                self.composeView.showPasswordHintView()
//            } else {
//                self.composeView.showPasswordAndConfirmDoesntMatch()
//            }
//            
//        case EncryptionStep.DefineHintPassword:
//            self.encryptionPasswordHint = composeView.encryptedPasswordTextField.text ?? ""
//            self.actualEncryptionStep = EncryptionStep.DefinePassword
//            self.composeView.showEncryptionDone()
//        default:
//            println("No step defined.")
//        }
//    }
//    
//    func composeView(composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker) {
//        var selectedContacts: [ContactVO] = [ContactVO]()
//        
//        if (picker == composeView.toContactPicker) {
//            selectedContacts = toSelectedContacts
//        } else if (picker == composeView.ccContactPicker) {
//            selectedContacts = ccSelectedContacts
//        } else if (picker == composeView.bccContactPicker) {
//            selectedContacts = bccSelectedContacts
//        }
//
//        selectedContacts.append(contact)
//    }
//    
//    func composeView(composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker) {
//
//        var contactIndex = -1
//        
//        var selectedContacts: [ContactVO] = [ContactVO]()
//        
//        if (picker == composeView.toContactPicker) {
//            selectedContacts = toSelectedContacts
//        } else if (picker == composeView.ccContactPicker) {
//            selectedContacts = ccSelectedContacts
//        } else if (picker == composeView.bccContactPicker) {
//            selectedContacts = bccSelectedContacts
//        }
//        
//        for (index, selectedContact) in enumerate(selectedContacts) {
//            if (contact.email == selectedContact.email) {
//                contactIndex = index
//            }
//        }
//        
//        if (contactIndex >= 0) {
//            selectedContacts.removeAtIndex(contactIndex)
//        }
//    }
//    
//    func composeViewDidTapAttachmentButton(composeView: ComposeView) {
//        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
//            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsViewController {
//                attachmentsViewController.delegate = self
//                
//                if let attachments = attachments {
//                    attachmentsViewController.attachments = attachments
//                }
//            }
//            
//            presentViewController(viewController, animated: true, completion: nil)
//        }
//    }
//}
//
//// MARK: - ComposeViewDataSource
//extension ComposeViewController: ComposeViewDataSource {
//    func composeViewContactsModelForPicker(composeView: ComposeView, picker: MBContactPicker) -> [AnyObject]! {
//        return contacts
//    }
//    
//    func composeViewSelectedContactsForPicker(composeView: ComposeView, picker: MBContactPicker) ->  [AnyObject]! {
//        
//        var selectedContacts: [ContactVO] = [ContactVO]()
//        
//        if (picker == composeView.toContactPicker) {
//            selectedContacts = toSelectedContacts
//        } else if (picker == composeView.ccContactPicker) {
//            selectedContacts = ccSelectedContacts
//        } else if (picker == composeView.bccContactPicker) {
//            selectedContacts = bccSelectedContacts
//        }
//        
//        return selectedContacts
//    }
//}
//
//
//// MARK: - Message extension
//
//extension String {
//    private func splitByComma() -> [String] {
//        return split(self) {$0 == ","}
//    }
//}
