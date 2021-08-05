//
//  ComposeViewModelImpl.swift
//  ProtonMail - Created on 8/15/15.
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
import ProtonCore_Networking
import ProtonCore_DataModel

class ComposeViewModelImpl : ComposeViewModel {
    
    enum RuntimeError : String, Error, CustomErrorVar {
        case no_address = "Can't find the public key for this address"
        var code: Int {
            get {
                return -1010
            }
        }
        
        var desc: String {
            get {
                return self.rawValue
            }
        }
        
        var reason: String {
            get {
                return self.rawValue
            }
        }
        
    }
    
    let messageService : MessageDataService
    let coreDataService: CoreDataService
    let user : UserManager
    /// Only use in share extension, to record if the share items over 25 mb or not
    private(set) var shareOverLimitationAttachment = false
    
    // for the share target to init composer VM
    init(subject: String, body: String, files: [FileData],
         action : ComposeMessageAction,
         msgService: MessageDataService,
         user: UserManager,
         coreDataService: CoreDataService) {

        self.messageService = msgService
        self.user = user
        self.coreDataService = coreDataService
        
        super.init()
        self.composerContext = coreDataService.makeComposerMainContext()
        self.message = nil
        self.setSubject(subject)
        self.setBody(body)
        self.messageAction = action

        self.collectDraft(subject,
                          body: body,
                          expir: 0,
                          pwd: "",
                          pwdHit: "")
        self.updateDraft()
        
        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
        let kDefaultAttachmentFileSize: Int = 25 * 1_000 * 1_000 // 25 mb
        var currentAttachmentSize: Int = 0
        for f in files {
            let size = f.contents.dataSize
            guard size < (kDefaultAttachmentFileSize - currentAttachmentSize) else {
                self.shareOverLimitationAttachment = true
                break
            }
            currentAttachmentSize += size
            f.contents.toAttachment(self.message!, fileName: f.name, type: f.ext, stripMetadata: stripMetadata).done { (attachment) in
                if let att = attachment {
                    let context = coreDataService.operationContext
                    context.performAndWait {
                        att.message = self.message!
                        _ = context.saveUpstreamIfNeeded()
                    }
                    if att.objectID.isTemporaryID {
                        context.performAndWait {
                            try? context.obtainPermanentIDs(for: [att])
                        }
                    }
                    self.uploadAtt(att)
                }
            }.cauterize()
        }
        
    }
    
   override func getUser() -> UserManager {
         return user
    }
    
    var attachments : [Attachment] = []
    /// inital composer viewmodel
    ///
    /// - Parameters:
    ///   - msg: optional value
    ///   - action: tell is the draft new / open exsiting / reply etc
    ///   - orignalLocation: if reply sent messages. need to to use the last to addresses fill the new to address
    init(msg: Message?, action : ComposeMessageAction, msgService: MessageDataService, user: UserManager, coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.messageService = msgService
        self.user = user
        
        super.init()
        self.composerContext = coreDataService.makeComposerMainContext()
        
        if msg == nil || msg?.draft == true {
            if let m = msg, let msgToEdit = try? self.composerContext?.existingObject(with: m.objectID) as? Message {
                self.message = msgToEdit
            }
            self.setSubject(self.message?.title ?? "")
        } else {
            if msg?.managedObjectContext == nil {
                self.message = nil
            } else {
                //TODO: -v4 change to composer context
                guard let m = msg, let msgToCopy = try? self.composerContext?.existingObject(with: m.objectID) as? Message else {
                    self.message = nil
                    fatalError("This should not happened.")
                }
                
                self.message = messageService.copyMessage(message: msgToCopy, copyAtts: action == ComposeMessageAction.forward, context: self.composerContext!)
                self.message?.action = action.rawValue as NSNumber?
                if action == ComposeMessageAction.reply || action == ComposeMessageAction.replyAll {
                    self.message?.action = action.rawValue as NSNumber?
                    if let title = self.message?.title {
                        if !title.hasRe() {
                            let re = LocalString._composer_short_reply
                            self.message?.title = "\(re) \(title)"
                        }
                    }
                } else if action == ComposeMessageAction.forward {
                    self.message?.action = action.rawValue as NSNumber?
                    if let title = self.message?.title {
                        if !( title.hasFwd() || title.hasFw() ) {
                            let fwd = LocalString._composer_short_forward
                            self.message?.title = "\(fwd) \(title)"
                        }
                    }
                    
                    /// add mime attachments if forward
                    if let mimeAtts = msg?.tempAtts {
                        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
                        for mimeAtt in mimeAtts {
                            mimeAtt.toAttachment(message: self.message, stripMetadata: stripMetadata).done { (attachment) in
                                if let att = attachment {
                                    self.attachments.append(att)
                                }
                            }.cauterize()
                        }
                    }
                } else {
                    
                }
            }
        }
        
        self.setSubject(self.message?.title ?? "")
        self.messageAction = action
        
        // get orignal message if from sent
        let fromSent: Bool = msg?.sentHardCheck ??  false
        self.updateContacts(fromSent)

    }
    
    deinit {
        PMLog.D("ComposeViewModelImpl deinit")
    }
    
    fileprivate let k12HourMinuteFormat = "h:mm a"
    fileprivate let k24HourMinuteFormat = "HH:mm"
    private func using12hClockFormat() -> Bool {
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        return !(pmRange == nil && amRange == nil)
    }
    
    override func uploadAtt(_ att: Attachment!) {
        if att.headerInfo == nil {
            att.setupHeaderInfo(isInline: false, contentID: nil)
        }
        self.updateDraft()
        messageService.upload(att: att)
        self.updateDraft()
    }
    
    override func uploadPubkey(_ att: Attachment!) {
        self.updateDraft()
        messageService.upload(pubKey: att)
        self.updateDraft()
    }
    
    override func deleteAtt(_ att: Attachment!) -> Promise<Void> {
        return messageService.delete(att: att).done { (_) in
            self.updateDraft()
        }
    }
    
    override func getAttachments() -> [Attachment]? {
        guard let attachments = self.message?.attachments.allObjects as? [Attachment] else {
            return []
        }
        return attachments.filter { !$0.isSoftDeleted }
    }
    
    override func uploadMimeAttachments() {
        if self.messageAction == .forward, attachments.count > 0 {
            self.updateDraft()
            for att in attachments {
                messageService.upload(att: att)
            }
            self.updateDraft()
        }
    }
    
    override func updateAddressID(_ address_id: String) -> Promise<Void> {
        return Promise { [weak self] seal in
            guard let message = self?.message else {
                let error = NSError(domain: "", code: -1,
                                    localizedDescription: LocalString._error_no_object)
                seal.reject(error)
                return
            }
            let context = self?.coreDataService.operationContext
            if let _ = self?.user.userinfo.userAddresses.first(where: { $0.addressID == address_id}) {
                context?.performAndWait {
                    if let messageInContext = try? context?.existingObject(with: message.objectID) as? Message {
                        messageInContext.nextAddressID = address_id
                    }
                    _ = context?.saveUpstreamIfNeeded()
                }
            }

            self?.messageService.updateAttKeyPacket(message: message, addressID: address_id)
            seal.fulfill_()
        }
    }
    
    override func getAddresses() -> [Address] {
        return self.user.addresses
    }
    
    override func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?) {
        if let _ = model as? ContactGroupVO {
            complete?(nil, -1)
            return
        }
        
        progress()
        
        let context = self.composerContext! // VALIDATE
        guard let c = model as? ContactVO else {
            complete?(nil, -1)
            return
        }
        
        guard let email = model.displayEmail else {
            complete?(nil, -1)
            return
        }

        let getEmail: Promise<KeysResponse> = self.user.apiService.run(route: UserEmailPubKeys.init(email: email))
        let contactService = self.user.contactService
        let getContact = contactService.fetch(byEmails: [email], context: context)
        when(fulfilled: getEmail, getContact).done { [weak self] keyRes, contacts in
            //internal emails
            guard let self = self else {
                complete?(c.lock, PGPType.none.rawValue)
                return
            }
            c.pgpType = self.getPGPType(keyRes: keyRes, contacts: contacts)
            complete?(c.lock, c.pgpType.rawValue)
        }.catch(policy: .allErrors) { (error) in
            var errCode: Int
            if let error = error as? ResponseError {
                errCode = error.responseCode ?? -1
            } else {
                let error = error as NSError
                errCode = error.code
            }
            PMLog.D(error.localizedDescription)
            defer {
                complete?(nil, errCode)
            }
            
            if errCode == 33101 {
                c.pgpType = .failed_server_validation
                self.showError?(LocalString._signle_address_invalid_error_content)
                return
            }
            
            // Code=33102 "Recipient could not be found"
            if errCode == 33102 {
                self.showError?(LocalString._recipient_not_found)
                return
            }
            
            if !c.email.isValidEmail() {
                errCode = 33102
                c.pgpType = .failed_validation
            }
        }
    }
    
    override func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        progress()
        let mails = contactGroup.getSelectedEmailData().map{$0.email}
        let reqs = mails.map { mail -> Promise<KeysResponse> in
            return self.user.apiService.run(route: UserEmailPubKeys(email: mail))
        }
        let context = self.composerContext! // VALIDATE
        let contactService = self.user.contactService
        let getContact = contactService.fetch(byEmails: mails, context: context)
        
        let keyReqs = when(fulfilled: reqs)
        when(fulfilled: getContact, keyReqs).done { [weak self] (contacts, keyResponse) in
            for (index, keyRes) in keyResponse.enumerated() {
                guard let self = self,
                      let mail = mails[safe: index] else {
                    continue
                }
                var contactArray: [PreContact] = []
                if let contact = contacts.first(where: { $0.email == mail }) {
                    contactArray.append(contact)
                }
                let pgpType = self.getPGPType(keyRes: keyRes,
                                              contacts: contactArray)
                contactGroup.update(mail: mail, pgpType: pgpType)
            }
            complete?(nil, 0)
        }.catch(policy: .allErrors) { (error) in
            var errCode: Int
            if let error = error as? ResponseError {
                errCode = error.responseCode ?? -1
            } else {
                let error = error as NSError
                errCode = error.code
            }
            PMLog.D(error.localizedDescription)
            defer {
                complete?(nil, errCode)
            }

            // Code=33102 "Recipient could not be found"
            if errCode == 33102 {
                LocalString._address_in_group_not_found_error.alertToast()
                return
            }
            
            for mail in mails {
                if mail.isValidEmail() {
                    continue
                }
                errCode = 33102
                LocalString._address_in_group_not_found_error.alertToast()
                break
            }
        }
    }
    
    override func getDefaultSendAddress() -> Address? {
        if let msg = self.message {
            var address: Address?
            if let id = msg.nextAddressID {
                address = self.user.userInfo.userAddresses.first(where: { $0.addressID == id })
            }
            return address ?? self.messageService.defaultAddress(msg)
        } else {
            if let addr = self.user.userInfo.userAddresses.defaultSendAddress() {
                return addr
            }
        }
        return nil
    }
    
    override func fromAddress() -> Address? {
        if let msg = self.message {
            return self.messageService.fromAddress(msg)
        }
        return nil
    }
    
    override func getCurrrentSignature(_ addr_id : String) -> String? {
        if let addr = self.user.userInfo.userAddresses.address(byID: addr_id) {
            return addr.signature
        }
        return nil
    }
    
    override func hasAttachment() -> Bool {
        return true;
    }
    
    /**
     Load the contacts and groups back for the message
     
     contact group only shows up in draft, so the reply, reply all, etc., no contact group will show up
    */
    fileprivate func updateContacts(_ origFromSent: Bool) {
        if let msg = message {
            switch messageAction
            {
            case .newDraft, .forward, .newDraftFromShare:
                break
            case .openDraft:
                let toContacts = self.toContacts(msg.toList) // Json to contact/group objects
                for cont in toContacts {
                    switch cont.modelType {
                    case .contact:
                        if let cont = cont as? ContactVO {
                            if !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                                self.toSelectedContacts.append(cont)
                            }
                        } else {
                            // TODO: error handling
                        }
                    case .contactGroup:
                        if let group = cont as? ContactGroupVO {
                            self.toSelectedContacts.append(group)
                        } else {
                            // TODO: error handling
                        }
                    }
                }
                
                let ccContacts = self.toContacts(msg.ccList)
                for cont in ccContacts {
                    switch cont.modelType {
                    case .contact:
                        if let cont = cont as? ContactVO {
                            if !cont.isDuplicatedWithContacts(self.ccSelectedContacts) {
                                self.ccSelectedContacts.append(cont)
                            }
                        } else {
                            // TODO: error handling
                        }
                    case .contactGroup:
                        if let group = cont as? ContactGroupVO {
                            self.ccSelectedContacts.append(group)
                        } else {
                            // TODO: error handling
                        }
                    }
                }
                
                let bccContacts = self.toContacts(msg.bccList)
                for cont in bccContacts {
                    switch cont.modelType {
                    case .contact:
                        if let cont = cont as? ContactVO {
                            if !cont.isDuplicatedWithContacts(self.bccSelectedContacts) {
                                self.bccSelectedContacts.append(cont)
                            }
                        } else {
                            // TODO: error handling
                        }
                    case .contactGroup:
                        if let group = cont as? ContactGroupVO {
                            self.bccSelectedContacts.append(group)
                        } else {
                            // TODO: error handling
                        }
                    }
                }
            case .reply:
                if origFromSent {
                    let toContacts = self.toContacts(msg.toList)
                    for cont in toContacts {
                        self.toSelectedContacts.append(cont)
                    }
                } else {
                    var senders: [ContactPickerModelProtocol] = []
                    let replytos = self.toContacts(msg.replyTos ?? "")
                    if replytos.count > 0 {
                        senders += replytos
                    } else {
                        if let newSender = self.toContact(msg.sender ?? "") {
                            senders.append(newSender)
                        } else {
                            //ignore
                        }
                    }
                    self.toSelectedContacts.append(contentsOf: senders)
                }
            case .replyAll:
                if origFromSent {
                    self.toContacts(msg.toList).forEach { self.toSelectedContacts.append($0) }
                    self.toContacts(msg.ccList).forEach { self.ccSelectedContacts.append($0) }
                    self.toContacts(msg.bccList).forEach { self.bccSelectedContacts.append($0) }
                } else {
                    let userAddress = self.user.addresses
                    var senders = [ContactPickerModelProtocol]()
                    let replytos = self.toContacts(msg.replyTos ?? "")
                    if replytos.count > 0 {
                        senders += replytos
                    } else {
                        if let newSender = self.toContact(msg.sender ?? "") {
                            senders.append(newSender)
                        } else {
                            //ignore
                        }
                    }
                    
                    for sender in senders {
                        if let sender = sender as? ContactVO,
                            !sender.isDuplicated(userAddress) {
                            self.toSelectedContacts.append(sender)
                        }
                    }
                    
                    let toContacts = self.toContacts(msg.toList)
                    for cont in toContacts {
                        if let cont = cont as? ContactVO,
                            !cont.isDuplicated(userAddress) && !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                            self.toSelectedContacts.append(cont)
                        }
                    }
                    if self.toSelectedContacts.count <= 0 {
                        self.toSelectedContacts.append(contentsOf: senders)
                    }
                    
                    self.toContacts(msg.ccList).compactMap { $0 as? ContactVO }
                        .filter { !$0.isDuplicated(userAddress) && !$0.isDuplicatedWithContacts(self.toSelectedContacts) }
                        .forEach { self.ccSelectedContacts.append($0) }
                    self.toContacts(msg.bccList).compactMap { $0 as? ContactVO }
                        .filter { !$0.isDuplicated(userAddress) && !$0.isDuplicatedWithContacts(self.toSelectedContacts) }
                        .forEach { self.bccSelectedContacts.append($0) }
                }
            }
        }
    }
    
    override func sendMessage() {
        async {
            //check if has extenral emails and if need attach key
            let userinfo = self.user.userInfo
            if userinfo.attachPublicKey == 1,
               let msg = self.message,
               let addr = self.messageService.defaultAddress(msg),
               let key = addr.keys.first,
               let data = key.publicKey.data(using: String.Encoding.utf8) {

                let filename = "publicKey - " + addr.email + " - " + key.shortFingerpritn + ".asc"
                var attached: Bool = false
                // check if key already attahced
                if let atts = self.getAttachments() {
                    for att in atts {
                        if att.fileName == filename {
                            attached = true
                            break
                        }
                    }
                }

                // attach key
                if attached == false {
                    let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
                    let attachment = try? `await`(data.toAttachment(msg, fileName: filename, type: "application/pgp-keys", stripMetadata: stripMetadata))
                    attachment?.setupHeaderInfo(isInline: false, contentID: nil)
                    self.uploadPubkey(attachment)
                }
            }

            self.updateDraft()
            self.messageService.send(inQueue: self.message) { [weak self] _, _, error in
                if error == nil {
                    self?.message?.attachments.compactMap { $0 as? Attachment }.forEach { $0.cleanLocalURLs() }
                }
            }
        }
    }
    
    override func collectDraft(_ title: String, body: String, expir:TimeInterval, pwd:String, pwdHit:String) {
        let mailboxPassword = self.user.mailboxPassword
        self.setSubject(title)

        let context = self.composerContext!
        context.performAndWait {
            if self.message == nil || self.message?.managedObjectContext == nil {
                self.message = self.messageService.messageWithLocation(recipientList: self.toJsonString(self.toSelectedContacts),
                                                                       bccList: self.toJsonString(self.bccSelectedContacts),
                                                                       ccList: self.toJsonString(self.ccSelectedContacts),
                                                                       title: self.getSubject(),
                                                                       encryptionPassword: "",
                                                                       passwordHint: "",
                                                                       expirationTimeInterval: expir,
                                                                       body: body,
                                                                       attachments: nil,
                                                                       mailbox_pwd: mailboxPassword,
                                                                       inManagedObjectContext: context)
                self.message?.password = pwd
                self.message?.unRead = false
                self.message?.passwordHint = pwdHit
                self.message?.expirationOffset = Int32(expir)
                
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
            } else {
                self.message?.toList = self.toJsonString(self.toSelectedContacts)
                self.message?.ccList = self.toJsonString(self.ccSelectedContacts)
                self.message?.bccList = self.toJsonString(self.bccSelectedContacts)
                self.message?.title = self.getSubject()
                self.message?.time = Date()
                self.message?.password = pwd
                self.message?.unRead = false
                self.message?.passwordHint = pwdHit
                self.message?.expirationOffset = Int32(expir)

                if let msg = self.message {
                    self.messageService.updateMessage(msg,
                                                      expirationTimeInterval: expir,
                                                      body: body,
                                                      attachments: nil,
                                                      mailbox_pwd: mailboxPassword)
                }
                
                if let error = context.saveUpstreamIfNeeded() {
                    PMLog.D(" error: \(error)")
                }
                
                if let msg = self.message, msg.objectID.isTemporaryID {
                    do {
                        try context.obtainPermanentIDs(for: [msg])
                    } catch {
                        PMLog.D("error: \(error)")
                    }
                }
            }
        }
    }
    
    override func updateEO(expirationTime: TimeInterval, pwd: String, pwdHint: String) -> Promise<Void> {
        return Promise { seal in
            if let msg = message {
                self.user.cacheService.updateExpirationOffset(of: msg, expirationTime: expirationTime, pwd: pwd, pwdHint: pwdHint) {
                    seal.fulfill_()
                }
            } else {
                seal.fulfill_()
            }
        }
    }
    
    override func updateDraft() {
        messageService.saveDraft(self.message);
    }
    
    override func deleteDraft() {
        guard let _message = self.message else {return}
        messageService.delete(messages: [_message], label: Message.Location.draft.rawValue)

    }
    
    override func markAsRead() {
        if let msg = message, msg.unRead {
            self.messageService.mark(messages: [msg], labelID: Message.Location.draft.rawValue, unRead: false)
        }
    }
    
    override func getHtmlBody() -> WebContents {        
        let globalRemoteContentMode: WebContents.RemoteContentPolicy = self.user.autoLoadRemoteImages ? .allowed : .disallowed
        
        var signature = self.getDefaultSendAddress()?.signature ?? self.user.userDefaultSignature
        signature = signature.ln2br()
        
        var mobileSignature = self.user.showMobileSignature ? "<div><br></div><div><br></div><div id=\"protonmail_mobile_signature_block\"><div>\(self.user.mobileSignature)</div></div>" : ""
        mobileSignature = mobileSignature.ln2br()
        
        let defaultSignature = self.user.defaultSignatureStatus ? "<div><br></div><div><br></div><div id=\"protonmail_signature_block\"  class=\"protonmail_signature_block\"><div>\(signature)</div></div>" : ""
        
        let head = "<html><head></head><body>"
        let foot = "</body></html>"
        let signatureHtml = "\(defaultSignature) \(mobileSignature)"

        switch messageAction {
        case .openDraft:
            var body = ""
            do {
                body = try self.messageService.decryptBodyIfNeeded(message: self.message!) ?? ""
            } catch let ex as NSError {
                PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                body = self.message!.bodyToHtml()
            }
            return .init(body: body, remoteContentMode: globalRemoteContentMode)
        case .reply, .replyAll:
            
            var body = ""
            do {
                body = try self.messageService.decryptBodyIfNeeded(message: self.message!) ?? ""
            } catch let ex as NSError {
                PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                body = self.message!.bodyToHtml()
            }
            
            if self.message?.isPlainText == true {
                body = body.encodeHtml()
                body = body.ln2br()
            }
            let clockFormat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc = message!.orginalTime?.formattedWith(timeFormat) ?? ""
            let sn : String! = (message?.managedObjectContext != nil) ? message!.senderContactVO.name : "unknow"
            let se : String! = message?.managedObjectContext != nil ? message!.senderContactVO.email : "unknow"
            
            var replyHeader = timeDesc + ", " + sn!
            replyHeader = replyHeader + " &lt;<a href=\"mailto:"
            replyHeader = replyHeader + se + "\" class=\"\">" + se + "</a>&gt;"
            
            let w = LocalString._composer_wrote
            let sp = "<div><br></div><div><br></div>\(replyHeader) \(w)</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "
            
            let result = " \(head) \(signatureHtml) \(sp) \(body)</blockquote><div><br></div><div><br></div>\(foot)"
            return .init(body: result, remoteContentMode: globalRemoteContentMode)
        case .forward:
            let clockFormat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc = message!.orginalTime?.formattedWith(timeFormat) ?? ""
            
            let fwdm = LocalString._composer_fwd_message
            let from = LocalString._general_from_label
            let dt = LocalString._composer_date_field
            let sj = LocalString._composer_subject_field
            let t = "\(LocalString._general_to_label):"
            let c = "\(LocalString._general_cc_label):"
            var forwardHeader =
                "---------- \(fwdm) ----------<br>\(from) " + message!.senderContactVO.name + "&lt;<a href=\"mailto:" + message!.senderContactVO.email + "\" class=\"\">" + message!.senderContactVO.email + "</a>&gt;<br>\(dt) \(timeDesc)<br>\(sj) \(message!.title)<br>"
            
            if message!.toList != "" {
                forwardHeader += "\(t) \(message!.toList.formatJsonContact(true))<br>"
            }
            
            if message!.ccList != "" {
                forwardHeader += "\(c) \(message!.ccList.formatJsonContact(true))<br>"
            }
            forwardHeader += ""
            var body = ""
            
            do {
                body = try self.messageService.decryptBodyIfNeeded(message: self.message!) ?? ""
            } catch let ex as NSError {
                PMLog.D("getHtmlBody OpenDraft error : \(ex)")
                body = self.message!.bodyToHtml()
            }
            
            if self.message?.isPlainText == true {
                body = body.encodeHtml()
                body = body.ln2br()
            }
            
            let sp = "<div><br></div><div><br></div><blockquote class=\"protonmail_quote\" type=\"cite\">\(forwardHeader)</div> "
            let result = "\(head)\(signatureHtml)\(sp)\(body)\(foot)"
            return .init(body: result, remoteContentMode: globalRemoteContentMode)
        case .newDraft:
            if !self.body.isEmpty {
                let newhtmlString = "\(head) \(self.body!) \(signatureHtml) \(foot)"
                self.body = ""
                return .init(body: newhtmlString, remoteContentMode: globalRemoteContentMode)
            }
            let body = signatureHtml.trim().isEmpty ? .empty : signatureHtml
            return .init(body: body, remoteContentMode: globalRemoteContentMode)
        case .newDraftFromShare:
            if !self.body.isEmpty {
                let newhtmlString = """
                \(head) \(self.body!.ln2br()) \(signatureHtml) \(foot)
                """
                
                return .init(body: newhtmlString, remoteContentMode: globalRemoteContentMode)
            } else if signatureHtml.trim().isEmpty {
                //add some space
                let ret_body = "<div><br></div><div><br></div><div><br></div><div><br></div>"
                return .init(body: ret_body, remoteContentMode: globalRemoteContentMode)
            }
            return .init(body: signatureHtml, remoteContentMode: globalRemoteContentMode)
        }
        
    }
}

extension ComposeViewModelImpl {
    /**
     Encode the recipient information in Contact and ContactGroupVO objects
     into JSON request format (for the message object in the API)
     
     Currently, the fields required in the message object are: Group, Address, and Name
    */
    func toJsonString(_ contacts : [ContactPickerModelProtocol]) -> String {
        //TODO:: could be improved 
        var out : [[String : String]] = [[String : String]]();
        for contact in contacts {
            switch contact.modelType {
            case .contact:
                let contact = contact as! ContactVO
                let to: [String : String] = [
                    "Group": "",
                    "Name" : contact.name,
                    "Address" : contact.email ?? ""
                ]
                out.append(to)
            case .contactGroup:
                let contactGroup = contact as! ContactGroupVO
                
                // load selected emails from the contact group
                for member in contactGroup.getSelectedEmailsWithDetail() {
                    let to: [String : String] = [
                        "Group": member.Group,
                        "Name" : member.Name,
                        "Address" : member.Address
                    ]
                    out.append(to)
                }
            }
        }
        
        let bytes : Data = try! JSONSerialization.data(withJSONObject: out, options: JSONSerialization.WritingOptions())
        let strJson : String = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)! as String
        
        return strJson
    }
    
    /**
     Decode the recipient information in Message Object from API
     into Contact and ContactGroupVO objects
     */
    func toContacts(_ json : String) -> [ContactPickerModelProtocol] {
        var out : [ContactPickerModelProtocol] = [];
        var groups = [String: [DraftEmailData]]() // [groupName: [DraftEmailData]]
        
        if let recipients : [[String : Any]] = json.parseJson() {
            // parse the contacts, and prepare the data for contact groups
            for dict in recipients {
                let group = dict["Group"] as? String ?? ""
                let name = dict["Name"] as? String ?? ""
                let address = dict["Address"] as? String ?? ""
                
                if group.isEmpty {
                    // contact
                    out.append(ContactVO(id: "", name: name, email: address))
                } else {
                    // contact group
                    let toInsert = DraftEmailData.init(name: name, email: address)
                    if var data = groups[group] {
                        data.append(toInsert)
                        groups.updateValue(data, forKey: group)
                    } else {
                        groups.updateValue([toInsert], forKey: group)
                    }
                }
            }
            
            // finish parsing contact groups
            for group in groups {
                let contactGroup = ContactGroupVO(ID: "", name: group.key)
                contactGroup.overwriteSelectedEmails(with: group.value)
                out.append(contactGroup)
            }
        }
        return out
    }
    
    func toContact(_ json : String) -> ContactVO? {
        var out : ContactVO? = nil
        let recipients : [String : String] = self.parse(json)

        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""

        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }
    
    func parse (_ json: String) -> [String:String] {
        if json.isEmpty {
            return ["" : ""];
        }
        do {
            let data : Data! = json.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:String]
            return decoded ?? ["" : ""]
        } catch {
            PMLog.D(" func parseJson() -> error error \(error)")
        }
        return ["":""]
    }
    
    private func getPGPType(keyRes: KeysResponse, contacts: [PreContact]) -> PGPType {
        if keyRes.recipientType == 1 {
            if let contact = contacts.first, contact.firstPgpKey != nil {
                return .internal_trusted_key
            } else {
                return .internal_normal
            }
        } else {
            if let contact = contacts.first {
                if contact.encrypt, contact.firstPgpKey != nil {
                    return .pgp_encrypt_trusted_key
                } else if contact.sign {
                    if let pwd = self.message?.password, pwd != "" {
                        return .eo
                    }
                    return .pgp_signed
                }
            } else {
                if let pwd = self.message?.password, pwd != "" {
                    return .eo
                } else if self.user.userInfo.sign == 1 {
                    return .pgp_signed
                } else {
                    return .none
                }
            }
        }
        return .none
    }
}
