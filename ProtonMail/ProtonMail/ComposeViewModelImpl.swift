//
//  ComposeViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class ComposeViewModelImpl : ComposeViewModel {
    
    init(msg: Message?, action : ComposeMessageAction!) {
        super.init()
        
        if msg == nil || msg?.location == MessageLocation.draft {
            self.message = msg
            self.setSubject(self.message?.title ?? "")
        }
        else
        {
            if msg?.managedObjectContext == nil {
                self.message = nil
            } else {
                self.message = msg?.copyMessage(action == ComposeMessageAction.Forward)
                self.message?.action = action.rawValue
                if action == ComposeMessageAction.Reply || action == ComposeMessageAction.ReplyAll {
                    if let title = self.message?.title {
                        if !title.hasRe() {
                            self.message?.title = "Re: \(title)"
                        }
                    }
                } else if action == ComposeMessageAction.Forward {
                    if let title = self.message?.title {
                        if !title.hasFwd() {
                            self.message?.title = "Fwd: \(title)"
                        }
                    }
                } else {
                }
            }
            //PMLog.D(message!);
        }
        
        self.setSubject(self.message?.title ?? "")
        self.messageAction = action
        self.updateContacts(msg?.location)
    }
    
    deinit {
        PMLog.D("ComposeViewModelImpl deinit")
    }
    
    override func uploadAtt(att: Attachment!) {
        sharedMessageDataService.uploadAttachment(att)
        self.updateDraft()
    }
    
    override func deleteAtt(att: Attachment!) {
        sharedMessageDataService.deleteAttachment(message?.messageID ?? "", att: att)
        self.updateDraft()
    }
    
    override func getAttachments() -> [Attachment]? {
        return self.message?.attachments.allObjects as? [Attachment]
    }
    
    override func updateAddressID(address_id: String) {
        self.message?.addressID = address_id
        self.updateDraft()
    }
    
    override func getAddresses() -> Array<Address> {
        return sharedUserDataService.userAddresses
    }
    
    override func getDefaultAddress() -> Address? {
        if self.message == nil {
            if let addr = sharedUserDataService.userAddresses.getDefaultAddress() {
                return addr
            }
        }
        return self.message?.defaultAddress
    }
    
    override func getCurrrentSignature(addr_id : String) -> String? {
        if let addr = sharedUserDataService.userAddresses.indexOfAddress(addr_id) {
            return addr.signature
        }
        return nil
    }
    
    override func hasAttachment() -> Bool {
        return true;
    }
    
    private func updateContacts(oldLocation : MessageLocation?)
    {
        if message != nil {
            switch messageAction!
            {
            case .NewDraft, .Forward:
                break;
            case .OpenDraft:
                let toContacts = self.toContacts(self.message!.recipientList)
                for cont in toContacts {
                    if !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                        self.toSelectedContacts.append(cont)
                    }
                }
                
                let ccContacts = self.toContacts(self.message!.ccList)
                for cont in ccContacts {
                    if  !cont.isDuplicatedWithContacts(self.ccSelectedContacts) {
                        self.ccSelectedContacts.append(cont)
                    }
                }
                let bccContacts = self.toContacts(self.message!.bccList)
                for cont in bccContacts {
                    if !cont.isDuplicatedWithContacts(self.bccSelectedContacts) {
                        self.bccSelectedContacts.append(cont)
                    }
                }
            case .Reply:
                if oldLocation == .outbox {
                    let toContacts = self.toContacts(self.message!.recipientList)
                    for cont in toContacts {
                        self.toSelectedContacts.append(cont)
                    }
                } else {
                    var sender : ContactVO!
                    if let replyToContact = self.toContact(self.message!.replyTo ?? "") {
                        sender = replyToContact
                    } else {
                        if let newSender = self.toContact(self.message!.senderObject ?? "") {
                            sender = newSender
                        } else {
                            sender = ContactVO(id: "", name: self.message!.senderName, email: self.message!.senderAddress)
                        }
                    }
                    
                    self.toSelectedContacts.append(sender)
                }
            case .ReplyAll:
                if oldLocation == .outbox {
                    let toContacts = self.toContacts(self.message!.recipientList)
                    for cont in toContacts {
                        self.toSelectedContacts.append(cont)
                    }
                    let senderContacts = self.toContacts(self.message!.ccList)
                    for cont in senderContacts {
                        self.ccSelectedContacts.append(cont)
                    }
                } else {
                    let userAddress = sharedUserDataService.userAddresses
                    var sender : ContactVO!
                    if let replyToContact = self.toContact(self.message!.replyTo ?? "") {
                        sender = replyToContact
                    } else {
                        if let newSender = self.toContact(self.message!.senderObject ?? "") {
                            sender = newSender
                        } else {
                            sender = ContactVO(id: "", name: self.message!.senderName, email: self.message!.senderAddress)
                        }
                    }
                    
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
                }
            }
        }
    }
    
    public override func sendMessage() {
        
        self.updateDraft()
        sharedMessageDataService.send(self.message?.messageID)  { task, response, error in
            
        }
        
    }
    
    override func collectDraft(title: String, body: String, expir:NSTimeInterval, pwd:String, pwdHit:String) {
        PMLog.D(self.toSelectedContacts)
        PMLog.D(self.ccSelectedContacts)
        PMLog.D(self.bccSelectedContacts)
        
        //self.setBody(body)
        self.setSubject(title)
        
        if message == nil || message?.managedObjectContext == nil {
            self.message = MessageHelper.messageWithLocation(MessageLocation.draft,
                                                             recipientList: toJsonString(self.toSelectedContacts),
                                                             bccList: toJsonString(self.bccSelectedContacts),
                                                             ccList: toJsonString(self.ccSelectedContacts),
                                                             title: self.subject,
                                                             encryptionPassword: "",
                                                             passwordHint: "",
                                                             expirationTimeInterval: expir,
                                                             body: body,
                                                             attachments: nil,
                                                             inManagedObjectContext: sharedCoreDataService.mainManagedObjectContext!)
        } else {
            self.message?.recipientList = toJsonString(self.toSelectedContacts)
            self.message?.ccList = toJsonString(self.ccSelectedContacts)
            self.message?.bccList = toJsonString(self.bccSelectedContacts)
            self.message?.title = self.subject
            self.message?.time = NSDate()
            self.message?.password = pwd
            self.message?.passwordHint = pwdHit
            self.message?.expirationOffset = Int32(expir)
            MessageHelper.updateMessage(self.message!, expirationTimeInterval: expir, body: body, attachments: nil)
            if let error = message!.managedObjectContext?.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
        
        PMLog.D(message!);
        
    }
    
    public override func updateDraft() {
        sharedMessageDataService.saveDraft(self.message);
    }
    
    override public func deleteDraft() {
        if let tmpLocation = self.message?.location {
            lastUpdatedStore.ReadMailboxMessage(tmpLocation)
        }
        sharedMessageDataService.deleteDraft(self.message);
    }
    
    public override func markAsRead() {
        if message != nil {
            message?.isRead = true;
            if let error = message!.managedObjectContext?.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            }
        }
    }
    
    override public func getHtmlBody() -> String {
        //sharedUserDataService.signature
        let signature = self.getDefaultAddress()?.signature ?? "\(sharedUserDataService.signature)"
        
        let mobileSignature = sharedUserDataService.showMobileSignature ? "<div><br></div><div><br></div><div id=\"protonmail_mobile_signature_block\">\(sharedUserDataService.mobileSignature)</div>" : ""
        
        let defaultSignature = sharedUserDataService.showDefaultSignature ? "<div><br></div><div><br></div><div class=\"protonmail_signature_block\">\(signature)</div>" : ""
        
        let htmlString = "\(defaultSignature) \(mobileSignature)";
        
        //PMLog.D("\(message?.addressID)")
        
        switch messageAction!
        {
        case .OpenDraft:
            do {
                let body = try message?.decryptBodyIfNeeded() ?? ""
                return body
            } catch let ex as NSError {
                PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                return self.message!.bodyToHtml()
            }
        case .Reply, .ReplyAll:
            
            var body = ""
            do {
                body = try message!.decryptBodyIfNeeded() ?? ""
            } catch let ex as NSError {
                PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                body = self.message!.bodyToHtml()
            }
            
            body = body.stringByStrippingStyleHTML()
            body = body.stringByStrippingBodyStyle()
            body = body.stringByPurifyHTML()
            
            let time = message!.orginalTime?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
            
            let sn = message?.managedObjectContext != nil ? message!.senderContactVO.name : "unknow"
            let se = message?.managedObjectContext != nil ? message!.senderContactVO.email : "unknow"
            
            let replyHeader = time + ", " + sn + " <'\(se)'>"
            let sp = "<div><br><div><div><br></div>\(replyHeader) wrote:</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "
            
            return "\(htmlString) \(sp) \(body)</blockquote>"
        case .Forward:
            let time = message!.orginalTime?.formattedWith("'On' EE, MMM d, yyyy 'at' h:mm a") ?? ""
            var forwardHeader = "---------- Forwarded message ----------<br>From: \( message!.senderContactVO.name) <'\(message!.senderContactVO.email)'> <br>Date: \(time)<br>Subject: \(message!.title)<br>"
            if message!.recipientList != "" {
                forwardHeader += "To: \(message!.recipientList.formatJsonContact())<br>"
            }
            
            if message!.ccList != "" {
                forwardHeader += "CC: \(message!.ccList.formatJsonContact())<br>"
            }
            forwardHeader += "<br><br>"
            var body = ""
            
            do {
                body = try message!.decryptBodyIfNeeded() ?? ""
            } catch let ex as NSError {
                PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                body = self.message!.bodyToHtml()
            }
            
            body = body.stringByStrippingStyleHTML()
            body = body.stringByStrippingBodyStyle()
            body = body.stringByPurifyHTML()
            
            let sp = "<div><br></div><div><br></div>\(forwardHeader) wrote:</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "
            return "\(defaultSignature) \(mobileSignature) \(sp) \(body)"
        case .NewDraft:
            if !self.body.isEmpty {
                let newhtmlString = " \(self.body) \(htmlString)"
                self.body = ""
                return newhtmlString
            }
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
        
        let bytes : NSData = try! NSJSONSerialization.dataWithJSONObject(out, options: NSJSONWritingOptions())
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
    
    func toContact(json : String) -> ContactVO? {
        var out : ContactVO? = nil
        let recipients : [String : String] = self.parse(json)
        
        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""
        
        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }
    
    func parse (json : String) -> [String:String] {
        if json.isEmpty {
            return ["" : ""];
        }
        do {
            let data : NSData! = json.dataUsingEncoding(NSUTF8StringEncoding)
            let decoded = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String:String]
            return decoded ?? ["" : ""]
        } catch {
            PMLog.D(" func parseJson() -> error error \(error)")
        }
        return ["":""]
    }
}



