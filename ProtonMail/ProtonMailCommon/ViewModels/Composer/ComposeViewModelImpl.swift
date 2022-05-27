//
//  ComposeViewModelImpl.swift
//  Proton Mail - Created on 8/15/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import SwiftSoup
import PromiseKit
import ProtonCore_Networking
import ProtonCore_DataModel

class ComposeViewModelImpl: ComposeViewModel {
    let user: UserManager
    /// Only use in share extension, to record if the share items over 25 mb or not
    private(set) var shareOverLimitationAttachment = false

    // for the share target to init composer VM
    init(subject: String, body: String, files: [FileData],
         action: ComposeMessageAction,
         msgService: MessageDataService,
         user: UserManager,
         coreDataContextProvider: CoreDataContextProviderProtocol) {
        self.user = user
        
        super.init(msgDataService: msgService,
                   contextProvider: coreDataContextProvider,
                   user: user)
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
            composerMessageHelper.addAttachment(f,
                                                shouldStripMetaData: stripMetadata) { attachment in
                guard let att = attachment else { return }
                self.uploadAtt(att)
            }
        }

    }

   override func getUser() -> UserManager {
         return user
    }

    var attachments: [Attachment] = []
    /// inital composer viewmodel
    ///
    /// - Parameters:
    ///   - msg: optional value
    ///   - action: tell is the draft new / open exsiting / reply etc
    ///   - orignalLocation: if reply sent messages. need to to use the last to addresses fill the new to address
    init(msg: Message?, action : ComposeMessageAction, msgService: MessageDataService, user: UserManager, coreDataContextProvider: CoreDataContextProviderProtocol) {
        self.user = user
        
        super.init(msgDataService: msgService,
                   contextProvider: coreDataContextProvider,
                   user: user)
        
        if msg == nil || msg?.draft == true {
            if let m = msg, let msgToEdit = try? self.composerMessageHelper.context.existingObject(with: m.objectID) as? Message {
                self.composerMessageHelper.setNewMessage(msgToEdit)
            }
            self.setSubject(self.composerMessageHelper.message?.title ?? "")
        } else {
            if msg?.managedObjectContext == nil {

            } else {
                //TODO: -v4 change to composer context
                guard let m = msg else {
                    fatalError("This should not happened.")
                }

                composerMessageHelper.copyAndCreateDraft(from: m,
                                                         shouldCopyAttachment: action == ComposeMessageAction.forward)
                composerMessageHelper.updateMessageByMessageAction(action)

                if action == ComposeMessageAction.forward {
                    /// add mime attachments if forward
                    if let mimeAtts = msg?.tempAtts {
                        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
                        for mimeAtt in mimeAtts {
                            composerMessageHelper.addMimeAttachments(attachment: mimeAtt,
                                                                     shouldStripMetaData: stripMetadata) { attachment in
                                if let att = attachment {
                                    self.attachments.append(att)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        self.setSubject(self.composerMessageHelper.message?.title ?? "")
        self.messageAction = action

        // get orignal message if from sent
        let fromSent: Bool = msg?.sentHardCheck ?? false
        self.updateContacts(fromSent)

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
        guard !self.user.isStorageExceeded else { return }
        self.user.usedSpace(plus: att.fileSize.int64Value)
        self.updateDraft()
        messageService.upload(pubKey: att)
        self.updateDraft()
    }

    override func deleteAtt(_ att: Attachment!) -> Promise<Void> {
        guard let attachment = att else {
            return Promise()
        }
        self.user.usedSpace(minus: att.fileSize.int64Value)
        return Promise { seal in
            composerMessageHelper.deleteAttachment(attachment) {
                self.updateDraft()
                seal.fulfill_()
            }
        }
    }

    override func getAttachments() -> [Attachment]? {
        return composerMessageHelper.attachments.filter { !$0.isSoftDeleted }
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
            guard self?.composerMessageHelper.message != nil else {
                let error = NSError(domain: "", code: -1,
                                    localizedDescription: LocalString._error_no_object)
                seal.reject(error)
                return
            }
            if let _ = self?.user.userinfo.userAddresses.first(where: { $0.addressID == address_id}) {
                composerMessageHelper.updateAddressID(addressID: address_id) {
                    seal.fulfill_()
                }
            } else {
                seal.fulfill_()
            }
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

        let context = composerMessageHelper.context
        
        progress()

        guard let c = model as? ContactVO else {
            complete?(nil, -1)
            return
        }

        guard let email = model.displayEmail else {
            complete?(nil, -1)
            return
        }

        let contactService = self.user.contactService
        let getContact = contactService.fetchAndVerifyContacts(byEmails: [email], context: context)
        getContact.done { [weak self] contacts in
            guard let self = self, let message = self.composerMessageHelper.message else {
                complete?(PGPType.none.lockImage, PGPType.none.rawValue)
                return
            }

            let helper = ContactPGPTypeHelper(internetConnectionStatusProvider: .init(),
                                              apiService: self.user.apiService,
                                              userSign: self.user.userinfo.sign,
                                              localContacts: contacts)
            let isMessageHavingPwd = message.password != .empty
            helper.calculatePGPType(email: email,
                                    isMessageHavingPwd: isMessageHavingPwd) { pgpType, errorCode, errorString in
                c.pgpType = pgpType
                if let errorCode = errorCode {
                    complete?(pgpType.lockImage, errorCode)
                } else {
                    complete?(pgpType.lockImage, pgpType.rawValue)
                }

                if let errorString = errorString {
                    self.showError?(errorString)
                }

            }
        }.catch(policy: .allErrors) { (error) in
            complete?(nil, -1)
        }
    }

    override func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        progress()
        let mails = contactGroup.getSelectedEmailData().map {$0.email}
        let reqs = mails.map { mail -> Promise<KeysResponse> in
            return self.user.apiService.run(route: UserEmailPubKeys(email: mail))
        }
        let context = composerMessageHelper.context
        let contactService = self.user.contactService
        let getContact = contactService.fetchAndVerifyContacts(byEmails: mails, context: context)

        let keyReqs = when(fulfilled: reqs)
        when(fulfilled: getContact, keyReqs).done { [weak self] (contacts, keyResponse) in
            guard let self = self, let message = self.composerMessageHelper.message else {
                complete?(nil, -1)
                return
            }

            let helper = ContactPGPTypeHelper(internetConnectionStatusProvider: .init(),
                                              apiService: self.user.apiService,
                                              userSign: self.user.userinfo.sign,
                                              localContacts: contacts)
            let isMessageHavingPwd = message.password != .empty

            for (index, keyRes) in keyResponse.enumerated() {
                guard let mail = mails[safe: index] else {
                    continue
                }
                var contactArray: [PreContact] = []
                if let contact = contacts.first(where: { $0.email == mail }) {
                    contactArray.append(contact)
                }
                let pgpType = helper.calculatePGPTypeWith(email: mail,
                                                          keyRes: keyRes,
                                                          contacts: contacts,
                                                          isMessageHavingPwd: isMessageHavingPwd)
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
            defer {
                complete?(nil, errCode)
            }

            if errCode == PGPTypeErrorCode.recipientNotFound.rawValue {
                LocalString._address_in_group_not_found_error.alertToast()
                return
            }

            for mail in mails {
                if mail.isValidEmail() {
                    continue
                }
                errCode = PGPTypeErrorCode.recipientNotFound.rawValue
                LocalString._address_in_group_not_found_error.alertToast()
                break
            }
        }
    }

    override func getDefaultSendAddress() -> Address? {
        if let msg = self.composerMessageHelper.message {
            var address: Address?
            if let id = msg.nextAddressID {
                address = self.user.userInfo.userAddresses.first(where: { $0.addressID == id })
            }
            return address ?? self.messageService.defaultAddress(MessageEntity(msg))
        } else {
            if let addr = self.user.userInfo.userAddresses.defaultSendAddress() {
                return addr
            }
        }
        return nil
    }

    override func fromAddress() -> Address? {
        if let msg = self.composerMessageHelper.message {
            return self.messageService.fromAddress(MessageEntity(msg))
        }
        return nil
    }

    override func getCurrrentSignature(_ addr_id: String) -> String? {
        if let addr = self.user.userInfo.userAddresses.address(byID: addr_id) {
            return addr.signature
        }
        return nil
    }

    /**
     Load the contacts and groups back for the message
     
     contact group only shows up in draft, so the reply, reply all, etc., no contact group will show up
    */
    fileprivate func updateContacts(_ origFromSent: Bool) {
        if let msg = composerMessageHelper.message {
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
                            // ignore
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
                            // ignore
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
            // check if has extenral emails and if need attach key
            let userinfo = self.user.userInfo
            if userinfo.attachPublicKey == 1,
               let msg = self.composerMessageHelper.message,
               let addr = self.messageService.defaultAddress(MessageEntity(msg)),
               let key = addr.keys.first,
               let data = key.publicKey.data(using: String.Encoding.utf8) {
                let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata

                if let attachmentToAdd = self.composerMessageHelper
                    .addPublicKeyIfNeeded(email: addr.email,
                                          fingerprint: key.shortFingerpritn,
                                          data: data,
                                          shouldStripMetaDate: stripMetadata) {
                    self.uploadPubkey(attachmentToAdd)
                }
            }

            self.updateDraft()
            guard let msg = self.composerMessageHelper.message else {
                return
            }
            self.messageService.send(inQueue: msg, completion: nil)
        }
    }
    
    override func collectDraft(_ title: String,
                               body: String,
                               expir: TimeInterval,
                               pwd: String,
                               pwdHit: String) {
        self.setSubject(title)

        guard let sendAddress = getDefaultSendAddress() else {
            return
        }

        composerMessageHelper.collectDraft(recipientList: self.toJsonString(self.toSelectedContacts),
                                           bccList: self.toJsonString(self.bccSelectedContacts),
                                           ccList: self.toJsonString(self.ccSelectedContacts),
                                           sendAddress: sendAddress,
                                           title: self.getSubject(),
                                           body: body,
                                           expiration: expir,
                                           password: pwd,
                                           passwordHint: pwdHit)
    }

    override func updateEO(expirationTime: TimeInterval, pwd: String, pwdHint: String, completion: @escaping () -> Void) {
        composerMessageHelper.updateExpirationOffset(expirationTime: expirationTime,
                                                     password: pwd,
                                                     passwordHint: pwdHint,
                                                     completion: completion)
    }

    override func updateDraft() {
        composerMessageHelper.updateDraft()
    }

    override func deleteDraft() {
        guard let message = self.composerMessageHelper.message else { return }
        messageService.delete(messages: [MessageEntity(message)],
                              label: Message.Location.draft.labelID)
    }

    override func markAsRead() {
        composerMessageHelper.markAsRead()
    }

    override func getHtmlBody() -> WebContents {
        let globalRemoteContentMode: WebContents.RemoteContentPolicy = self.user.autoLoadRemoteImages ? .allowed : .disallowed

        let head = "<html><head></head><body>"
        let foot = "</body></html>"
        let signatureHtml = self.htmlSignature()

        switch messageAction {
        case .openDraft:
            let msg = composerMessageHelper.message!
            var body = ""
            var css: String?
            do {
                body = try self.messageService.messageDecrypter.decrypt(message: msg)
                if CSSMagic.darkStyleSupportLevel(htmlString: body, isNewsLetter: false, isPlainText: false) == .protonSupport {
                    css = CSSMagic.generateCSSForDarkMode(htmlString: body)
                }
            } catch {
                body = msg.bodyToHtml()
            }
            return .init(body: body, remoteContentMode: globalRemoteContentMode, supplementCSS: css)
        case .reply, .replyAll:
            let msg = composerMessageHelper.message!
            var body = ""
            do {
                body = try self.messageService.messageDecrypter.decrypt(message: msg)
            } catch {
                body = msg.bodyToHtml()
            }
            
            if msg.isPlainText == true {
                body = body.encodeHtml()
                body = body.ln2br()
            }
            let clockFormat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc = msg.orginalTime?.formattedWith(timeFormat) ?? ""
            let sn: String! = (msg.managedObjectContext != nil) ? msg.senderContactVO.name : "unknow"
            let se: String! = msg.managedObjectContext != nil ? msg.senderContactVO.email : "unknow"
            
            var replyHeader = timeDesc + ", " + sn!
            replyHeader = replyHeader + " &lt;<a href=\"mailto:"
            replyHeader = replyHeader + se + "\" class=\"\">" + se + "</a>&gt;"

            let w = LocalString._composer_wrote
            let sp = "<div><br></div><div><br></div>\(replyHeader) \(w)</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "

            let result = " \(head) \(signatureHtml) \(sp) \(body)</blockquote>\(foot)"
            var css: String?
            if CSSMagic.darkStyleSupportLevel(htmlString: result, isNewsLetter: false, isPlainText: false) == .protonSupport {
                css = CSSMagic.generateCSSForDarkMode(htmlString: result)
            }
            return .init(body: result, remoteContentMode: globalRemoteContentMode, supplementCSS: css)
        case .forward:
            let msg = composerMessageHelper.message!
            let clockFormat = using12hClockFormat() ? k12HourMinuteFormat : k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc = msg.orginalTime?.formattedWith(timeFormat) ?? ""
            
            let fwdm = LocalString._composer_fwd_message
            let from = LocalString._general_from_label
            let dt = LocalString._composer_date_field
            let sj = LocalString._composer_subject_field
            let t = "\(LocalString._general_to_label):"
            let c = "\(LocalString._general_cc_label):"
            var forwardHeader =
                "---------- \(fwdm) ----------<br>\(from) " + msg.senderContactVO.name + "&lt;<a href=\"mailto:" + msg.senderContactVO.email + "\" class=\"\">" + msg.senderContactVO.email + "</a>&gt;<br>\(dt) \(timeDesc)<br>\(sj) \(msg.title)<br>"
            
            if msg.toList != "" {
                forwardHeader += "\(t) \(msg.toList.formatJsonContact(true))<br>"
            }
            
            if msg.ccList != "" {
                forwardHeader += "\(c) \(msg.ccList.formatJsonContact(true))<br>"
            }
            forwardHeader += ""
            var body = ""

            do {
                body = try self.messageService.messageDecrypter.decrypt(message: msg)
            } catch {
                body = msg.bodyToHtml()
            }
            
            if msg.isPlainText == true {
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
            var css: String?
            if CSSMagic.darkStyleSupportLevel(htmlString: body, isNewsLetter: false, isPlainText: false) == .protonSupport {
                css = CSSMagic.generateCSSForDarkMode(htmlString: body)
            }
            return .init(body: body, remoteContentMode: globalRemoteContentMode, supplementCSS: css)
        case .newDraftFromShare:
            if !self.body.isEmpty {
                let newhtmlString = """
                \(head) \(self.body!.ln2br()) \(signatureHtml) \(foot)
                """

                return .init(body: newhtmlString, remoteContentMode: globalRemoteContentMode)
            } else if signatureHtml.trim().isEmpty {
                // add some space
                let ret_body = "<div><br></div><div><br></div><div><br></div><div><br></div>"
                return .init(body: ret_body, remoteContentMode: globalRemoteContentMode)
            }
            return .init(body: signatureHtml, remoteContentMode: globalRemoteContentMode)
        }

    }

    override func getNormalAttachmentNum() -> Int {
        guard let messageObject = self.composerMessageHelper.message else { return 0 }
        let attachments = messageObject.attachments
            .allObjects
            .compactMap({ $0 as? Attachment })
            .filter({ !$0.inline() && !$0.isSoftDeleted })
        return attachments.count
    }

    override func needAttachRemindAlert(subject: String,
                                        body: String,
                                        attachmentNum: Int) -> Bool {
        // If the message contains attachments
        // It contains keywords or not doesn't important
        if attachmentNum > 0 { return false }

        let content = "\(subject) \(body.body(strippedFromQuotes: true))"
        let language = LanguageManager.currentLanguageEnum()
        return AttachReminderHelper.hasAttachKeyword(content: content,
                                                     language: language)
    }

    override func isEmptyDraft() -> Bool {
        if let message = self.composerMessageHelper.message,
           message.subject.isEmpty,
           (message.toList == "[]" || message.toList.isEmpty),
           (message.ccList == "[]" || message.ccList.isEmpty),
           (message.bccList == "[]" || message.bccList.isEmpty),
           message.numAttachments.intValue == 0 {
            let decryptedBody = (try? self.user.messageService.messageDecrypter.decrypt(message: message)) ?? .empty
            let bodyDocument = try? SwiftSoup.parse(decryptedBody)
            let body = try? bodyDocument?.body()?.text()

            let signatureDocument = try? SwiftSoup.parse(self.htmlSignature())
            let signature = try? signatureDocument?.body()?.text()
            return (body?.isEmpty ?? false) || body == signature
        }
        return false
    }
}

extension ComposeViewModelImpl {
    /**
     Encode the recipient information in Contact and ContactGroupVO objects
     into JSON request format (for the message object in the API)
     
     Currently, the fields required in the message object are: Group, Address, and Name
    */
    func toJsonString(_ contacts: [ContactPickerModelProtocol]) -> String {
        // TODO:: could be improved 
        var out: [[String: String]] = [[String: String]]()
        for contact in contacts {
            switch contact.modelType {
            case .contact:
                let contact = contact as! ContactVO
                let to: [String: String] = [
                    "Group": "",
                    "Name": contact.name,
                    "Address": contact.email ?? ""
                ]
                out.append(to)
            case .contactGroup:
                let contactGroup = contact as! ContactGroupVO

                // load selected emails from the contact group
                for member in contactGroup.getSelectedEmailsWithDetail() {
                    let to: [String: String] = [
                        "Group": member.Group,
                        "Name": member.Name,
                        "Address": member.Address
                    ]
                    out.append(to)
                }
            }
        }

        let bytes: Data = try! JSONSerialization.data(withJSONObject: out, options: JSONSerialization.WritingOptions())
        let strJson: String = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)! as String

        return strJson
    }

    /**
     Decode the recipient information in Message Object from API
     into Contact and ContactGroupVO objects
     */
    func toContacts(_ json: String) -> [ContactPickerModelProtocol] {
        var out: [ContactPickerModelProtocol] = []
        var groups = [String: [DraftEmailData]]() // [groupName: [DraftEmailData]]

        if let recipients: [[String: Any]] = json.parseJson() {
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

    func toContact(_ json: String) -> ContactVO? {
        var out: ContactVO?
        let recipients: [String: String] = self.parse(json)

        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""

        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }

    func parse (_ json: String) -> [String: String] {
        if json.isEmpty {
            return ["": ""]
        }
        do {
            let data: Data! = json.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: String]
            return decoded ?? ["": ""]
        } catch {
        }
        return ["": ""]
    }

    func htmlSignature() -> String {
        var signature = self.getDefaultSendAddress()?.signature ?? self.user.userDefaultSignature
        signature = signature.ln2br()

        var mobileSignature = self.user.showMobileSignature ? "<div id=\"protonmail_mobile_signature_block\"><div>\(self.user.mobileSignature)</div></div>" : ""
        mobileSignature = mobileSignature.ln2br()

        let defaultSignature = self.user.defaultSignatureStatus ? "<div><br></div><div><br></div><div id=\"protonmail_signature_block\"  class=\"protonmail_signature_block\"><div>\(signature)</div></div>" : ""
        let mobileBr = defaultSignature.isEmpty ? "<div><br></div><div><br></div>": "<div class=\"signature_br\"><br></div><div class=\"signature_br\"><br></div>"

        let signatureHtml = "\(defaultSignature) \(mobileBr) \(mobileSignature)"
        return signatureHtml
    }
}
