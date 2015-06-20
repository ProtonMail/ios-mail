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
        
        self.updateContacts()
    }
    
    private func updateContacts()
    {
        if message != nil {
            self.toSelectedContacts = toContacts(self.message!.recipientList)
            self.ccSelectedContacts = toContacts(self.message!.ccList)
            self.bccSelectedContacts = toContacts(self.message!.bccList)
        }
    }
    
    public override func sendMessage() {
        if hasDraft && message == nil {
            //send;
        }
        else {
            //save

            //send
        }
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
            let body = message!.decryptBodyIfNeeded(nil) ?? ""
            return body
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