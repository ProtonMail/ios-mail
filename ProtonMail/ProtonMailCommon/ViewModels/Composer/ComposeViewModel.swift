//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

protocol FileData {
    var name: String { get set }
    var ext: String { get set }
    var contents: AttachmentConvertible { get set }
}

struct ConcreteFileData<Base: AttachmentConvertible>: FileData {
    var name: String
    var ext: String
    var contents: AttachmentConvertible
    
    init(name: String, ext: String, contents: AttachmentConvertible) {
        self.name = name
        self.ext = ext
        self.contents = contents
    }
}


class ComposeViewModel {
    private let maxNumberOfRecipients: Int = 25
    var message : Message?
    var messageAction : ComposeMessageAction!
    var toSelectedContacts: [ContactVO] = [ContactVO]()
    var ccSelectedContacts: [ContactVO] = [ContactVO]()
    var bccSelectedContacts: [ContactVO] = [ContactVO]()
    var contacts: [ContactVO] = [ContactVO]()
    
    var subject : String! = ""
    var body : String! = ""
    
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
    
    init() { }
    
    func validateNumberOfRecipients() -> Bool {
        let overallRecipients = [toSelectedContacts, ccSelectedContacts, bccSelectedContacts].map{ $0.count }.reduce(0, +)
        return overallRecipients < self.maxNumberOfRecipients
    }
    
    func getSubject() -> String {
        return self.subject
    }
    
    func setSubject(_ sub : String) {
        self.subject = sub
    }
    
    func setBody(_ body : String) {
        self.body = body
    }
    
     func addToContacts(_ contacts: ContactVO! ) {
        toSelectedContacts.append(contacts)
    }
    
     func addCcContacts(_ contacts: ContactVO! ) {
        ccSelectedContacts.append(contacts)
    }
    
     func addBccContacts(_ contacts: ContactVO! ) {
        bccSelectedContacts.append(contacts)
    }
    
    func getActionType() -> ComposeMessageAction {
        return messageAction
    }
    
    ///
    func sendMessage() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func updateDraft() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func deleteDraft() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func uploadAtt(_ att : Attachment!) {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func deleteAtt(_ att : Attachment!) {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func markAsRead() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func getDefaultComposeBody() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func getHtmlBody() -> String {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
        return ""
    }
    
    func collectDraft(_ title:String, body:String, expir:TimeInterval, pwd:String, pwdHit:String) -> Void {
         NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    func updateEO(expir:TimeInterval, pwd:String, pwdHit:String) -> Void {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    
    func getAttachments() -> [Attachment]? {
        fatalError("This method must be overridden")
    }
    
    func updateAddressID (_ address_id : String) -> Promise<Void>  {
        fatalError("This method must be overridden")
    }
    
    func getAddresses () -> [Address] {
        fatalError("This method must be overridden")
    }
   
    func getDefaultSendAddress() -> Address? {
        fatalError("This method must be overridden")
    }
    
    func fromAddress() -> Address? {
        fatalError("This method must be overridden")
    }
    
    func getCurrrentSignature(_ addr_id : String) -> String? {
        fatalError("This method must be overridden")
    }
    
    func hasAttachment () -> Bool {
        fatalError("This method must be overridden")
    }
    
    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?) {
        fatalError("This method must be overridden")
    }
}



