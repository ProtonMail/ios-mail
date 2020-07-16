//
//  ComposeViewModel.swift
//  ProtonMail - Created on 6/18/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import PromiseKit
import AwaitKit

//TODO:: change to enum
struct EncryptionStep {
    static public let DefinePassword = "DefinePassword"
    static public let ConfirmPassword = "ConfirmPassword"
    static public let DefineHintPassword = "DefineHintPassword"
}

enum ComposeMessageAction: Int, CustomStringConvertible {
    case reply = 0
    case replyAll = 1
    case forward = 2
    case newDraft = 3
    case openDraft = 4
    case newDraftFromShare = 5
    
    /// localized description
    public var description : String {
        get {
            switch(self) {
            case .reply:
                return LocalString._general_reply_button
            case .replyAll:
                return LocalString._general_replyall_button
            case .forward:
                return LocalString._general_forward_button
            case .newDraft, .newDraftFromShare:
                return LocalString._general_draft_action
            case .openDraft:
                return ""
            }
        }
    }
}

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


class ComposeViewModel: NSObject {
    @objc dynamic var message: Message?
    var messageAction : ComposeMessageAction = .newDraft
    var toSelectedContacts: [ContactPickerModelProtocol] = []
    var ccSelectedContacts: [ContactPickerModelProtocol] = []
    var bccSelectedContacts: [ContactPickerModelProtocol] = []
    
    private var _subject : String! = ""
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
    
    func isValidNumberOfRecipients() -> Bool {
        return true
    }
    
    func getSubject() -> String {
        return self._subject
    }
    
    func setSubject(_ sub : String) {
        self._subject = sub
    }
    
    func setBody(_ body : String) {
        self.body = body
    }
    
     func addToContacts(_ contacts: ContactPickerModelProtocol! ) {
        toSelectedContacts.append(contacts)
    }
    
     func addCcContacts(_ contacts: ContactPickerModelProtocol! ) {
        ccSelectedContacts.append(contacts)
    }
    
     func addBccContacts(_ contacts: ContactPickerModelProtocol! ) {
        bccSelectedContacts.append(contacts)
    }
    
    func getActionType() -> ComposeMessageAction {
        return messageAction
    }
    
    func uploadMimeAttachments() {
        
    }
    
    func getUser() -> UserManager {
          fatalError("This method must be overridden")
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
    
    func uploadPubkey(_ att: Attachment!) {
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
    
    func getHtmlBody() -> WebContents {
        NSException(name:NSExceptionName(rawValue: "name"), reason:"reason", userInfo:nil).raise()
        return WebContents(body: "", remoteContentMode: .lockdown)
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



