//
//  ComposeViewControllerN.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/27/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class ComposeViewControllerN : ProtonMailViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    private var composeView : ComposeViewN!
    private var htmlEditor : HtmlEditorViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.composeView = ComposeViewN(nibName: "ComposeViewN", bundle: nil)
        //self.composeView.delegate = self

        
        htmlEditor = HtmlEditorViewController()
        htmlEditor.delegate = self
        
        scrollView.addSubview(composeView.view);
        scrollView.addSubview(htmlEditor.view);
        
        let f = scrollView.frame
        composeView.view.frame = CGRect(x: 0, y: 0, width: f.width, height: 250)
        htmlEditor.view.frame = CGRect(x: 0, y: f.height, width: f.width, height: 100)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       // scrollView.contentSize = CGSize(width: scrollView.frame.width, height: 2000)
       // let frame = scrollView.contentSize;
    }
    
    private func updateViewSize()
    {
        
    }
}


extension ComposeViewControllerN : HtmlEditorViewControllerDelegate {
    func editorSizeChanged(size: CGSize) {
    
        println("EditorSize:\(size)")
        
        htmlEditor.view.mas_updateConstraints{ (make) -> Void in
            make.top.equalTo()(200)
            make.left.equalTo()(self.scrollView)
            make.right.equalTo()(self.scrollView)
            make.height.equalTo()(size.height)
        }
        let s = composeView.view.frame.height;
       // self.htmlEditor.view.frame = CGRect(x: 0, y: 200, width: size.width, height: size.height)
        
        self.scrollView.contentSize = CGSize(width: scrollView.frame.width, height: 200 + htmlEditor.view.frame.height)
        
        self.htmlEditor.setFrame(CGRect(x: 0, y: 10, width: size.width, height: size.height))
        
        println("EditorFrame:\( self.htmlEditor.view.frame)")
        //println("EditorScrollView:\( self.htmlEditor)")
        println("scrollViewSize:\( self.scrollView.contentSize)")

    }
}

//extension ComposeViewControllerN : ComposeViewNDataSource {
//    
//}

//
//
//extension ComposeViewControllerN : ComposeViewNDelegate {
//    
//    func composeViewDidSizeChanged(composeView: ComposeViewN, size: CGSize) {
//        
//    }
//    
//    func composeViewDidTapCancelButton(composeView: ComposeView) {
////        let dismiss: (() -> Void) = {
////            if self.action == self.draftAction {
////                self.navigationController?.popViewControllerAnimated(true)
////            } else {
////                self.dismissViewControllerAnimated(true, completion: nil)
////            }
////        }
////        
////        if composeView.hasContent || ((attachments?.count ?? 0) > 0) {
////            let alertController = UIAlertController(title: NSLocalizedString("Confirmation"), message: nil, preferredStyle: .ActionSheet)
////            alertController.addAction(UIAlertAction(title: NSLocalizedString("Save draft"), style: .Default, handler: { (action) -> Void in
////                sharedMessageDataService.saveDraft(
////                    recipientList: composeView.toContacts,
////                    bccList: composeView.bccContacts,
////                    ccList: composeView.ccContacts,
////                    title: composeView.subjectTitle,
////                    encryptionPassword: self.encryptionPassword,
////                    passwordHint: self.encryptionPasswordHint,
////                    expirationTimeInterval: composeView.expirationTimeInterval,
////                    body: self.htmlEditor.getHTML(),
////                    attachments: self.attachments)
////                
////                dismiss()
////            }))
////            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
////            alertController.addAction(UIAlertAction(title: NSLocalizedString("Discard draft"), style: .Destructive, handler: { (action) -> Void in
////                dismiss()
////            }))
////            
////            presentViewController(alertController, animated: true, completion: nil)
////        } else {
////            dismiss()
////        }
//    }
//    
//    func composeViewDidTapSendButton(composeView: ComposeView) {
////        sharedMessageDataService.send(
////            recipientList: composeView.toContacts,
////            bccList: composeView.bccContacts,
////            ccList: composeView.ccContacts,
////            title: composeView.subjectTitle,
////            encryptionPassword: encryptionPassword,
////            passwordHint: encryptionPasswordHint,
////            expirationTimeInterval: composeView.expirationTimeInterval,
////            body: self.htmlEditor.getHTML(),
////            attachments: attachments,
////            completion: {_, _, error in
////                if error == nil {
////                    if let message = self.message {
////                        println("MessageID after send:\(message.messageID)")
////                        println("Message Location : \(message.location )")
////                        if(message.messageID != "0" && message.location == MessageLocation.draft)
////                        {
////                            message.location = .trash
////                        }
////                        if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
////                            NSLog("\(__FUNCTION__) error: \(error)")
////                        }
////                    }
////                }
////        })
////        
////        if presentingViewController != nil {
////            dismissViewControllerAnimated(true, completion: nil)
////        } else {
////            navigationController?.popViewControllerAnimated(true)
////        }
//    }
//    
//    func composeViewDidTapEncryptedButton(composeView: ComposeView) {
//       // self.actualEncryptionStep = EncryptionStep.DefinePassword
//       // self.composeView.showDefinePasswordView()
//       // self.composeView.hidePasswordAndConfirmDoesntMatch()
//    }
//    
//    func composeViewDidTapNextButton(composeView: ComposeView) {
////        switch(actualEncryptionStep) {
////        case EncryptionStep.DefinePassword:
////            self.encryptionPassword = composeView.encryptedPasswordTextField.text ?? ""
////            self.actualEncryptionStep = EncryptionStep.ConfirmPassword
////            self.composeView.showConfirmPasswordView()
////            
////        case EncryptionStep.ConfirmPassword:
////            self.encryptionConfirmPassword = composeView.encryptedPasswordTextField.text ?? ""
////            
////            if (self.encryptionPassword == self.encryptionConfirmPassword) {
////                self.actualEncryptionStep = EncryptionStep.DefineHintPassword
////                self.composeView.hidePasswordAndConfirmDoesntMatch()
////                self.composeView.showPasswordHintView()
////            } else {
////                self.composeView.showPasswordAndConfirmDoesntMatch()
////            }
////            
////        case EncryptionStep.DefineHintPassword:
////            self.encryptionPasswordHint = composeView.encryptedPasswordTextField.text ?? ""
////            self.actualEncryptionStep = EncryptionStep.DefinePassword
////            self.composeView.showEncryptionDone()
////        default:
////            println("No step defined.")
////        }
//    }
//    
//    func composeView(composeView: ComposeView, didAddContact contact: ContactVO, toPicker picker: MBContactPicker) {
////        var selectedContacts: [ContactVO] = [ContactVO]()
////        
////        if (picker == composeView.toContactPicker) {
////            selectedContacts = toSelectedContacts
////        } else if (picker == composeView.ccContactPicker) {
////            selectedContacts = ccSelectedContacts
////        } else if (picker == composeView.bccContactPicker) {
////            selectedContacts = bccSelectedContacts
////        }
////        
////        selectedContacts.append(contact)
//    }
//    
//    func composeView(composeView: ComposeView, didRemoveContact contact: ContactVO, fromPicker picker: MBContactPicker) {
//        
////        var contactIndex = -1
////        
////        var selectedContacts: [ContactVO] = [ContactVO]()
////        
////        if (picker == composeView.toContactPicker) {
////            selectedContacts = toSelectedContacts
////        } else if (picker == composeView.ccContactPicker) {
////            selectedContacts = ccSelectedContacts
////        } else if (picker == composeView.bccContactPicker) {
////            selectedContacts = bccSelectedContacts
////        }
////        
////        for (index, selectedContact) in enumerate(selectedContacts) {
////            if (contact.email == selectedContact.email) {
////                contactIndex = index
////            }
////        }
////        
////        if (contactIndex >= 0) {
////            selectedContacts.removeAtIndex(contactIndex)
////        }
//    }
//    
//    func composeViewDidTapAttachmentButton(composeView: ComposeView) {
////        if let viewController = UIStoryboard.instantiateInitialViewController(storyboard: .attachments) as? UINavigationController {
////            if let attachmentsViewController = viewController.viewControllers.first as? AttachmentsViewController {
////                attachmentsViewController.delegate = self
////                
////                if let attachments = attachments {
////                    attachmentsViewController.attachments = attachments
////                }
////            }
////            
////            presentViewController(viewController, animated: true, completion: nil)
////        }
//    }
//
//}
//


///
extension ComposeViewControllerN : ComposeViewNDelegate{
    //
}


