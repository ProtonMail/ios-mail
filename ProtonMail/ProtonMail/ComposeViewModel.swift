//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



public class ComposeViewModel {
    var message : Message?
    var messageAction : ComposeMessageAction!
    var toSelectedContacts: [ContactVO]! = [ContactVO]()
    var ccSelectedContacts: [ContactVO]! = [ContactVO]()
    var bccSelectedContacts: [ContactVO]! = [ContactVO]()
    var contacts: [ContactVO]! = [ContactVO]()
    
    var hasDraft : Bool = false;
    var toChanged : Bool = false;
    var ccChanged : Bool = false;
    var bccChanged : Bool = false;
    var titleChanged : Bool = false;
    var bodyChanged : Bool = false;
    
    public init() { }
    
    public func getSubject() -> String {
        return self.message?.title ?? ""
    }
    
    internal func addToContacts(contacts: ContactVO! ) {
        toSelectedContacts.append(contacts)
    }
    
    func getActionType() -> ComposeMessageAction {
        return messageAction
    }
    
    ///
    public func sendMessage() {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
    
    public func updateDraft() {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
    
    public func deleteDraft() {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
    
    public func uploadDraft() {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
    
    public func markAsRead() {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
    
    public func getDefaultComposeBody() {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
    
    public func getHtmlBody() -> String {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
        return ""
    }
    
    func collectDraft(to: [ContactVO], cc:[ContactVO], bcc: [ContactVO], title:String, body:String ) -> Void {
         NSException(name:"name", reason:"reason", userInfo:nil).raise()
    }
}

public class ComposeViewModelImpl : ComposeViewModel {

    init(msg: Message?, action : ComposeMessageAction!) {
        super.init()
        self.message = msg
        self.messageAction = action
    }
    
//  public override func collectDraft(to: [ContactVO], cc:[ContactVO], bcc: [ContactVO], title:String, body:String ) -> Void {
//        
//  }
    
    public override func sendMessage() {
        if hasDraft && message == nil {
            //send;
        }
        else {
            //save
//            MessageHelper.messageWithLocation(<#location: MessageLocation#>, recipientList: <#String#>, bccList: <#String#>, ccList: <#String#>, title: <#String#>, encryptionPassword: <#String#>, passwordHint: <#String#>, expirationTimeInterval: <#NSTimeInterval#>, body: <#String#>, attachments: <#[AnyObject]?#>, inManagedObjectContext: <#NSManagedObjectContext#>)
//            
//            sharedMessageDataService.saveDraft(recipientList: <#String#>, bccList: <#String#>, ccList: <#String#>, title: <#String#>, encryptionPassword: <#String#>, passwordHint: <#String#>, expirationTimeInterval: <#NSTimeInterval#>, body: <#String#>, attachments: <#[AnyObject]?#>)
            
            //send
        }

        
        
        //        sharedMessageDataService.send(
        //            recipientList: self.composeView.toContacts,
        //            bccList: self.composeView.bccContacts,
        //            ccList: self.composeView.ccContacts,
        //            title: self.composeView.subjectTitle,
        //            encryptionPassword: self.encryptionPassword,
        //            passwordHint: self.encryptionPasswordHint,
        //            expirationTimeInterval: self.composeView.expirationTimeInterval,
        //            body: self.composeView.htmlEditor.getHTML(),
        //            attachments: self.attachments,
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
    }
    
    override func collectDraft(to: [ContactVO], cc: [ContactVO], bcc: [ContactVO], title: String, body: String) {
        
    }
    
    public override func updateDraft()
    {
        if hasDraft && message == nil {
            //send;
        }
        else {
            //save
            
            self.message = MessageHelper.messageWithLocation(MessageLocation.draft,
                recipientList: "[{\"Name\": \"Feng\", \"Address\" : \"zhj4478@protonmail.ch\"}]",
                bccList: "[]",
                ccList: "[]",
                title: "this is a test draft",
                encryptionPassword: "",
                passwordHint: "",
                expirationTimeInterval: 0,
                body: "",
                attachments: nil,
                inManagedObjectContext: sharedCoreDataService.mainManagedObjectContext!)
            
            sharedMessageDataService.saveDraft(self.message);
            
        }
        //        sharedMessageDataService.saveDraft(
        //            recipientList: self.composeView.toContacts,
        //            bccList: self.composeView.bccContacts,
        //            ccList: self.composeView.ccContacts,
        //            title: self.composeView.subjectTitle,
        //            encryptionPassword: self.encryptionPassword,
        //            passwordHint: self.encryptionPasswordHint,
        //            expirationTimeInterval: self.composeView.expirationTimeInterval,
        //            body: self.composeView.htmlEditor.getHTML(),
        //            attachments: self.attachments)
    }
    
    override public func deleteDraft() {
        //        sharedMessageDataService.saveDraft(
        //            recipientList: self.composeView.toContacts,
        //            bccList: self.composeView.bccContacts,
        //            ccList: self.composeView.ccContacts,
        //            title: self.composeView.subjectTitle,
        //            encryptionPassword: self.encryptionPassword,
        //            passwordHint: self.encryptionPasswordHint,
        //            expirationTimeInterval: self.composeView.expirationTimeInterval,
        //            body: self.composeView.htmlEditor.getHTML(),
        //            attachments: self.attachments)
    }
    
    public override func markAsRead() {
        if message != nil {
            message?.isRead = true;
            if let error = message!.managedObjectContext?.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    override public func getHtmlBody() -> String {
        let signature = !sharedUserDataService.signature.isEmpty ? "\n\n\(sharedUserDataService.signature)" : ""
        let htmlString = "<div><br></div><div><br></div><div><br></div><div><br></div>\(signature)";
//        case ComposeMessageAction.Reply = 0
//        case ComposeMessageAction.ReplyAll = 1
//        case ComposeMessageAction.Forward = 2
//        case ComposeMessageAction.OpenDraft = 4
        switch messageAction!
        {
        case ComposeMessageAction.NewDraft:
            return htmlString
        case ComposeMessageAction.OpenDraft:
            return htmlString
        default:
            return htmlString
            
        }
        
    }
    
}