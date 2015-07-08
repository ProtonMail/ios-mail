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
    
    var hasDraft : Bool {
        get{
            return message?.isDetailDownloaded ?? false
        }
    }
    var needsUpdate : Bool {
        get{
            return toChanged || ccChanged || bccChanged || titleChanged || bodyChanged
        }
    }
    
    var toChanged : Bool = false;
    var ccChanged : Bool = false;
    var bccChanged : Bool = false;
    var titleChanged : Bool = false;
    var bodyChanged : Bool = false;
    var userAddress : Array<Address>!

        
    
    public init() { }
    
    public func getSubject() -> String {
        return self.message?.subject ?? ""
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
    
    func uploadAtt(att : Attachment!) {
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
        
        userAddress = sharedUserDataService.userAddresses
        
        if msg == nil || msg?.location == MessageLocation.draft {
             self.message = msg
        }
        else
        {
           self.message = msg?.copyMessage()
        }
        
        self.messageAction = action
        
        self.updateContacts()
    }
    
    override func uploadAtt(att: Attachment!) {
        self.updateDraft()
        sharedMessageDataService.uploadAttachment(att)
    }
    
    private func updateContacts()
    {
        if message != nil {
            switch messageAction!
            {
            case .OpenDraft, .NewDraft, .Forward:
                break;
            case .Reply:
                let sender = ContactVO(id: "", name: self.message!.senderName, email: self.message!.sender)
                self.toSelectedContacts.append(sender)
                break;
            case .ReplyAll:
                let sender = ContactVO(id: "", name: self.message!.senderName, email: self.message!.sender)
                
                if  !sender.isDuplicated(userAddress) {
                    self.toSelectedContacts.append(sender)
                }
                
                let toContacts = self.toContacts(self.message!.recipientList)
                for cont in toContacts {
                    if  !cont.isDuplicated(userAddress) && !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                        self.toSelectedContacts.append(cont)
                    }
                }
                
                if self.toSelectedContacts.count <= 0 {
                    self.toSelectedContacts.append(sender)
                }
                
                let senderContacts = self.toContacts(self.message!.ccList)
                for cont in senderContacts {
                    if  !cont.isDuplicated(userAddress) && !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                        self.ccSelectedContacts.append(cont)
                    }
                }
                
                break;
            default:
                break;
            }

            
            
            
            //self.bccSelectedContacts = toContacts(self.message!.bccList)
        }
    }
    
    public override func sendMessage() {
        

        self.updateDraft()
        sharedMessageDataService.send(self.message?.messageID, completion: nil)
        
//        if hasDraft && message != nil {
//            //send;
//        }
//        else {
//            //save
//            //send
//        }
    }
    
    override func collectDraft(to: [ContactVO], cc: [ContactVO], bcc: [ContactVO], title: String, body: String) {
        
        self.toSelectedContacts = to
        self.ccSelectedContacts = cc
        self.bccSelectedContacts = bcc
        
        if message == nil {
            self.message = MessageHelper.messageWithLocation(MessageLocation.draft,
                recipientList: toJsonString(self.toSelectedContacts),
                bccList: toJsonString(self.bccSelectedContacts),
                ccList: toJsonString(self.ccSelectedContacts),
                title: title,
                encryptionPassword: "",
                passwordHint: "",
                expirationTimeInterval: 0,
                body: body,
                attachments: nil,
                inManagedObjectContext: sharedCoreDataService.mainManagedObjectContext!)
        } else {
            self.message?.recipientList = toJsonString(self.toSelectedContacts)
            self.message?.ccList = toJsonString(self.ccSelectedContacts)
            self.message?.bccList = toJsonString(self.bccSelectedContacts)
            self.message?.title = title
            self.message?.time = NSDate()
            MessageHelper.updateMessage(self.message!, expirationTimeInterval: 0, body: body, attachments: nil)
            if let error = message!.managedObjectContext?.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    public override func updateDraft() {
        sharedMessageDataService.saveDraft(self.message);
    }
    
    override public func deleteDraft() {
        sharedMessageDataService.deleteDraft(self.message);
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
        let htmlString = "<div><br></div><div><br></div><div><br></div><div><br></div>\(signature)<div><br></div><div><br></div>";
        switch messageAction!
        {
        case .OpenDraft:
            let body = message!.decryptBodyIfNeeded(nil) ?? ""
            return body
        case .Reply, .ReplyAll:
            // composeView.subject.text = "Re: " + viewModel.getSubject()
            let replyMessage = NSLocalizedString("Reply message")
            let body = message!.decryptBodyIfNeeded(nil) ?? ""
            let time = message!.time?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
            let replyHeader = time + ", " + message!.senderName + " <'\(message!.sender)'>"
            let sp = "<div>\(replyHeader) wrote:</div><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\"><tbody><tr><td align=\"center\" valign=\"top\"> <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"background-color:transparent;border-bottom:0;border-bottom:solid 1px #00929f\" width=\"600\"> "
            return "\(htmlString) \(sp) \(body)</blockquote>"
        case .Forward:
            //composeView.subject.text = "Fwd: \(message.title)"
            
            let time = message!.time?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
            var forwardHeader = "<br><br><br>---------- Forwarded message ----------<br>From: \(message!.senderName)<br>Date: \(time)<br>Subject: \(message!.title)<br>"
            if message!.recipientList != "" {
                forwardHeader += "To: \(message!.recipientList.formatJsonContact())<br>"
            }
            
            if message!.ccList != "" {
                forwardHeader += "CC: \(message!.ccList.formatJsonContact())<br>"
            }
            forwardHeader += "<br><br><br>"
            let body = message!.decryptBodyIfNeeded(nil) ?? ""
            
            return "<br><br><br>\(signature) \(forwardHeader) \(body)"
        case .NewDraft:
            return htmlString
        default:
            return htmlString
        }
    }
    
}




extension ComposeViewModelImpl {
    func toJsonString(contacts : [ContactVO]) -> String {
        
        var out : [[String : String]] = [[String : String]]();
        for contact in contacts {
            let to : [String : String] = ["Name" : contact.name ?? "", "Address" : contact.email ?? ""]
            out.append(to)
        }
        
        let bytes : NSData = NSJSONSerialization.dataWithJSONObject(out, options: NSJSONWritingOptions.allZeros, error: nil)!
        let strJson : String = NSString(data: bytes, encoding: NSUTF8StringEncoding)! as String
        
        return strJson
    }
    func toContacts(json : String) -> [ContactVO] {
        
        var out : [ContactVO] = [ContactVO]();
        let recipients : [[String : String]] = json.parseJson()!
        for dict:[String : String] in recipients {
            out.append(ContactVO(id: "", name: dict["Name"], email: dict["Address"]))
        }
        return out
    }
}