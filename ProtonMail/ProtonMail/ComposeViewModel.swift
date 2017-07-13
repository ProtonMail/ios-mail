//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


open class ComposeViewModel {
    public var message : Message?
    public var messageAction : ComposeMessageAction!
    public var toSelectedContacts: [ContactVO]! = [ContactVO]()
    public var ccSelectedContacts: [ContactVO]! = [ContactVO]()
    public var bccSelectedContacts: [ContactVO]! = [ContactVO]()
    public var contacts: [ContactVO]! = [ContactVO]()
    
    var subject : String! = ""
    var body : String! = ""
    
    public var hasDraft : Bool {
        get{
            return message?.isDetailDownloaded ?? false
        }
    }
    public var needsUpdate : Bool {
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
    
    open func getSubject() -> String {
        return self.subject
        //return self.message?.subject ?? ""
    }
    
    open func setSubject(_ sub : String) {
        self.subject = sub
    }
    
    open func setBody(_ body : String) {
        self.body = body
    }
    
    public  func addToContacts(_ contacts: ContactVO! ) {
        toSelectedContacts.append(contacts)
    }
    
    public  func addCcContacts(_ contacts: ContactVO! ) {
        ccSelectedContacts.append(contacts)
    }
    
    public  func addBccContacts(_ contacts: ContactVO! ) {
        bccSelectedContacts.append(contacts)
    }
    
    public func getActionType() -> ComposeMessageAction {
        return messageAction
    }
    
    ///
    open func sendMessage() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    open func updateDraft() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    open func deleteDraft() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    public func uploadAtt(_ att : Attachment!) {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    public func deleteAtt(_ att : Attachment!) {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    open func markAsRead() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    open func getDefaultComposeBody() {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    open func getHtmlBody() -> String {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
        return ""
    }
    
    public func collectDraft(_ title:String, body:String, expir:TimeInterval, pwd:String, pwdHit:String) -> Void {
         NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
    }
    
    public func getAttachments() -> [Attachment]? {
        fatalError("This method must be overridden")
    }
    
    public func updateAddressID (_ address_id : String) {
        fatalError("This method must be overridden")
    }
    
    public func getAddresses () -> Array<Address> {
        fatalError("This method must be overridden")
    }
   
    public func getDefaultAddress () -> Address? {
        fatalError("This method must be overridden")
    }
    
    public func getCurrrentSignature(_ addr_id : String) -> String? {
        fatalError("This method must be overridden")
    }
    
    public func hasAttachment () -> Bool {
        fatalError("This method must be overridden")
    }
}



