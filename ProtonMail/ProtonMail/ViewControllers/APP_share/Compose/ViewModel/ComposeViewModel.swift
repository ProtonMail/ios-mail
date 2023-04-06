//
//  ComposeViewModel.swift
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

import CoreData
import Foundation
import PromiseKit
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonMailAnalytics
import SwiftSoup

class ComposeViewModel: NSObject {
    /// Only to notify ComposeContainerViewModel that contacts changed
    @objc private(set) dynamic var contactsChange: Int = 0
    @objc dynamic var contentHeight: CGFloat = 0.1

    let user: UserManager
    /// Only use in share extension, to record if the share items over 25 mb or not
    private(set) var shareOverLimitationAttachment = false
    let composerMessageHelper: ComposerMessageHelper
    let messageService: MessageDataService
    let coreDataContextProvider: CoreDataContextProviderProtocol
    let isEditingScheduleMsg: Bool
    let originalScheduledTime: OriginalScheduleDate?
    private let dependencies: Dependencies
    var urlSchemesToBeHandle: Set<String> {
        let schemes: [HTTPRequestSecureLoader.ProtonScheme] = [.http, .https, .noProtocol]
        return Set(schemes.map(\.rawValue))
    }

    private(set) var contacts: [ContactPickerModelProtocol] = []
    private var emailsController: NSFetchedResultsController<Email>?

    private(set) var phoneContacts: [ContactPickerModelProtocol] = []

    private(set) var messageAction: ComposeMessageAction = .newDraft
    private(set) var subject: String = .empty
    var body: String = .empty
    var showError: ((String) -> Void)?
    var deliveryTime: Date?

    var toSelectedContacts: [ContactPickerModelProtocol] = [] {
        didSet { self.contactsChange += 1 }
    }

    var ccSelectedContacts: [ContactPickerModelProtocol] = [] {
        didSet { self.contactsChange += 1 }
    }

    var bccSelectedContacts: [ContactPickerModelProtocol] = [] {
        didSet { self.contactsChange += 1 }
    }

    var currentAttachmentsSize: Int {
        return composerMessageHelper.attachmentSize
    }

    var imageProxyEnabled: Bool {
        return UserInfo.isImageProxyAvailable && user.userInfo.imageProxy.contains(.imageProxy)
    }

    init(
        subject: String,
        body: String,
        files: [FileData],
        action: ComposeMessageAction,
        msgService: MessageDataService,
        user: UserManager,
        coreDataContextProvider: CoreDataContextProviderProtocol,
        internetStatusProvider: InternetConnectionStatusProvider,
        originalScheduledTime: OriginalScheduleDate? = nil,
        dependencies: Dependencies? = nil
    ) {
        self.user = user
        self.messageService = msgService
        self.coreDataContextProvider = coreDataContextProvider
        self.isEditingScheduleMsg = false
        self.composerMessageHelper = ComposerMessageHelper(
            dependencies: .init(
                messageDataService: messageService,
                cacheService: user.cacheService,
                contextProvider: coreDataContextProvider
            ),
            user: user
        )
        // We have dependencies as an optional input parameter to avoid making
        // a huge refactor but allowing the dependencies injection open for testing.
        self.dependencies = dependencies ?? Dependencies(
            fetchAndVerifyContacts: FetchAndVerifyContacts(user: user),
            internetStatusProvider: internetStatusProvider,
            fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
            contactProvider: user.contactService
        )

        self.subject = subject
        self.body = body
        self.messageAction = action
        self.originalScheduledTime = originalScheduledTime

        super.init()

        self.collectDraft(subject,
                          body: body,
                          expir: 0,
                          pwd: "",
                          pwdHit: "")
        self.updateDraft()

        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
        var currentAttachmentSize = 0
        for file in files {
            let size = file.contents.dataSize
            guard size < (Constants.kDefaultAttachmentFileSize - currentAttachmentSize) else {
                self.shareOverLimitationAttachment = true
                break
            }
            currentAttachmentSize += size
            composerMessageHelper.addAttachment(file,
                                                shouldStripMetaData: stripMetadata) { _ in
                self.updateDraft()
                self.composerMessageHelper.updateAttachmentView?()
            }
        }
    }

    init(
        msg: Message?,
        action: ComposeMessageAction,
        msgService: MessageDataService,
        user: UserManager,
        coreDataContextProvider: CoreDataContextProviderProtocol,
        internetStatusProvider: InternetConnectionStatusProvider,
        isEditingScheduleMsg: Bool = false,
        originalScheduledTime: OriginalScheduleDate? = nil,
        dependencies: Dependencies? = nil
    ) {
        self.user = user
        self.messageService = msgService
        self.coreDataContextProvider = coreDataContextProvider
        self.isEditingScheduleMsg = isEditingScheduleMsg
        self.originalScheduledTime = originalScheduledTime
        self.composerMessageHelper = ComposerMessageHelper(
            dependencies: .init(
                messageDataService: messageService,
                cacheService: user.cacheService,
                contextProvider: coreDataContextProvider
            ),
            user: user
        )

        // We have dependencies as an optional input parameter to avoid making
        // a huge refactor but allowing the dependencies injection open for testing.
        self.dependencies = dependencies ?? Dependencies(
            fetchAndVerifyContacts: FetchAndVerifyContacts(user: user),
            internetStatusProvider: internetStatusProvider,
            fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
            contactProvider: user.contactService
        )

        super.init()

        if msg == nil || msg?.draft == true {
            if let msg = msg {
                self.composerMessageHelper.setNewMessage(objectID: msg.objectID)
            }
            self.subject = self.composerMessageHelper.draft?.title ?? ""
        } else if msg?.managedObjectContext != nil {
            // TODO: -v4 change to composer context
            guard let msg = msg else {
                fatalError("This should not happened.")
            }

            composerMessageHelper.copyAndCreateDraft(from: msg,
                                                     shouldCopyAttachment: action == ComposeMessageAction.forward)
            composerMessageHelper.updateMessageByMessageAction(action)

            if action == ComposeMessageAction.forward {
                /// add mime attachments if forward
                if let mimeAtts = msg.tempAtts {
                    let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
                    for mimeAtt in mimeAtts {
                        composerMessageHelper.addMimeAttachments(
                            attachment: mimeAtt,
                            shouldStripMetaData: stripMetadata,
                            completion: { _ in }
                        )
                    }
                }
            }
        }

        self.subject = self.composerMessageHelper.draft?.title ?? ""
        self.messageAction = action

        // get original message if from sent
        let fromSent: Bool = msg?.sentHardCheck ?? false
        self.updateContacts(fromSent)
    }

    func getAttachments() -> [AttachmentEntity]? {
        return composerMessageHelper.attachments
            .filter { !$0.isSoftDeleted }
            .sorted(by: { $0.order < $1.order })
    }

    func getAddresses() -> [Address] {
        return self.user.addresses
    }

    private func showToastIfNeeded(errorCode: Int) {
        if errorCode == PGPTypeErrorCode.recipientNotFound.rawValue {
            LocalString._address_in_group_not_found_error.alertToast()
        }
    }

    func getDefaultSendAddress() -> Address? {
        if let draft = self.composerMessageHelper.draft {
            var address: Address?
            if let id = draft.nextAddressID {
                address = self.user.userInfo.userAddresses.first(where: { $0.addressID == id })
            }
            return address ?? self.messageService.defaultUserAddress(of: draft.sendAddressID)
        } else {
            if let addr = self.user.userInfo.userAddresses.defaultSendAddress() {
                return addr
            }
        }
        return nil
    }

    func fromAddress() -> Address? {
        if let draft = self.composerMessageHelper.draft {
            return self.messageService.userAddress(of: draft.sendAddressID)
        }
        return nil
    }

    func getCurrentSignature(_ addressId: String) -> String? {
        if let addr = self.user.userInfo.userAddresses.address(byID: addressId) {
            return addr.signature
        }
        return nil
    }

    // check if has external emails and if need attach key
    private func uploadPublicKeyIfNeeded(completion: @escaping () -> Void) {
        let userinfo = self.user.userInfo

        guard userinfo.attachPublicKey == 1,
              let draft = self.composerMessageHelper.draft,
              let addr = self.messageService.defaultUserAddress(of: draft.sendAddressID),
              let key = addr.keys.first else {
            completion()
            return
        }

        let data = Data(key.publicKey.utf8)
        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata

        self.composerMessageHelper.addPublicKeyIfNeeded(
            email: addr.email,
            fingerprint: key.shortFingerprint,
            data: data,
            shouldStripMetaDate: stripMetadata
        ) { _ in
            completion()
        }
    }

    func getHtmlBody() -> WebContents {
        let globalRemoteContentMode: WebContents.RemoteContentPolicy =
            (user.userInfo.hideRemoteImages != 0) ? .disallowed : .allowed

        let head = "<html><head></head><body>"
        let foot = "</body></html>"
        let signatureHtml = self.htmlSignature()

        switch messageAction {
        case .openDraft:
            var css: String?
            let body = composerMessageHelper.decryptBody()
            let document = CSSMagic.parse(htmlString: body)
            if CSSMagic.darkStyleSupportLevel(document: document) == .protonSupport {
                css = CSSMagic.generateCSSForDarkMode(document: document)
            }
            return .init(body: body, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded, supplementCSS: css)
        case .reply, .replyAll:
            let msg = composerMessageHelper.draft!
            let body = composerMessageHelper.decryptBody()

            let clockFormat: String = using12hClockFormat() ? Constants.k12HourMinuteFormat : Constants.k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc: String = msg.originalTime?.formattedWith(timeFormat) ?? ""
            let senderName: String = msg.senderVO?.name ?? "unknown"
            let senderEmail: String = msg.senderVO?.email ?? "unknown"

            var replyHeader = "\(timeDesc), \(senderName)"
            replyHeader.append(contentsOf: " &lt;<a href=\"mailto:")
            replyHeader.append(contentsOf: "\(replyHeader)\(senderName)\" class=\"\">\(senderEmail)</a>&gt;")

            let w = LocalString._composer_wrote
            let sp = "<div><br></div><div><br></div>\(replyHeader) \(w)</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "

            let result = " \(head) \(signatureHtml) \(sp) \(body)</blockquote>\(foot)"
            var css: String?
            let document = CSSMagic.parse(htmlString: result)
            if CSSMagic.darkStyleSupportLevel(document: document) == .protonSupport {
                css = CSSMagic.generateCSSForDarkMode(document: document)
            }
            return .init(body: result, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded, supplementCSS: css)
        case .forward:
            let msg = composerMessageHelper.draft!
            let clockFormat = using12hClockFormat() ? Constants.k12HourMinuteFormat : Constants.k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc = msg.originalTime?.formattedWith(timeFormat) ?? ""

            let fwdm = LocalString._composer_fwd_message
            let from = LocalString._general_from_label
            let dt = LocalString._composer_date_field
            let sj = LocalString._composer_subject_field
            let t = "\(LocalString._general_to_label):"
            let c = "\(LocalString._general_cc_label):"
            let senderName: String = msg.senderVO?.name ?? .empty
            let senderEmail: String = msg.senderVO?.email ?? .empty

            var forwardHeader =
                "---------- \(fwdm) ----------<br>\(from) \(senderName)&lt;<a href=\"mailto:\(senderEmail)\" class=\"\">\(senderEmail)"
            forwardHeader.append(contentsOf: "</a>&gt;<br>\(dt) \(timeDesc)<br>\(sj) \(msg.title)<br>")

            if !msg.recipientList.isEmpty {
                forwardHeader.append(contentsOf: "\(t) \(msg.recipientList.formatJsonContact(true))<br>")
            }

            if !msg.ccList.isEmpty {
                forwardHeader.append(contentsOf: "\(c) \(msg.ccList.formatJsonContact(true))<br>")
            }
            let body = composerMessageHelper.decryptBody()

            let sp = "<div><br></div><div><br></div><blockquote class=\"protonmail_quote\" type=\"cite\">\(forwardHeader)</div> "
            let result = "\(head)\(signatureHtml)\(sp)\(body)\(foot)"
            return .init(body: result, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded)
        case .newDraft:
            if !self.body.isEmpty {
                let newHTMLString = "\(head) \(self.body) \(signatureHtml) \(foot)"
                self.body = ""
                return .init(body: newHTMLString, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded)
            }
            let body: String = signatureHtml.trim().isEmpty ? .empty : signatureHtml
            var css: String?
            let document = CSSMagic.parse(htmlString: body)
            if CSSMagic.darkStyleSupportLevel(document: document) == .protonSupport {
                css = CSSMagic.generateCSSForDarkMode(document: document)
            }
            return .init(body: body, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded, supplementCSS: css)
        case .newDraftFromShare:
            if !self.body.isEmpty {
                let newHTMLString = """
                \(head) \(self.body.ln2br()) \(signatureHtml) \(foot)
                """

                return .init(body: newHTMLString, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded)
            } else if signatureHtml.trim().isEmpty {
                // add some space
                let defaultBody = "<div><br></div><div><br></div><div><br></div><div><br></div>"
                return .init(body: defaultBody, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded)
            }
            return .init(body: signatureHtml, remoteContentMode: globalRemoteContentMode, messageDisplayMode: .expanded)
        }
    }

    func getNormalAttachmentNum() -> Int {
        guard let draft = self.composerMessageHelper.draft else { return 0 }
        let attachments = draft.attachments
            .filter { !$0.isInline && !$0.isSoftDeleted }
        return attachments.count
    }

    func needAttachRemindAlert(subject: String,
                               body: String) -> Bool {
        // If the message contains attachments
        // It contains keywords or not doesn't important
        if getNormalAttachmentNum() > 0 { return false }

        let content = "\(subject) \(body.body(strippedFromQuotes: true))"
        let language = LanguageManager().currentLanguage()
        return AttachReminderHelper.hasAttachKeyword(content: content,
                                                     language: language)
    }

    func isEmptyDraft() -> Bool {
        if let draft = self.composerMessageHelper.draft,
           draft.title.isEmpty,
           draft.recipientList == "[]" || draft.recipientList.isEmpty,
           draft.ccList == "[]" || draft.ccList.isEmpty,
           draft.bccList == "[]" || draft.bccList.isEmpty,
           draft.numAttachments == 0 {
            let decryptedBody = composerMessageHelper.decryptBody()
            let bodyDocument = try? SwiftSoup.parse(decryptedBody)
            let body = try? bodyDocument?.body()?.text()

            let signatureDocument = try? SwiftSoup.parse(self.htmlSignature())
            let signature = try? signatureDocument?.body()?.text()
            return (body?.isEmpty ?? false) || body == signature
        }
        return false
    }
}

// MARK: - Actions

extension ComposeViewModel {
    func updateDraft() {
        composerMessageHelper.uploadDraft()
    }

    func deleteDraft() {
        guard let rawMessage = composerMessageHelper.getMessageEntity() else { return }

        messageService.delete(messages: [rawMessage],
                              label: Message.Location.draft.labelID)
    }

    func markAsRead() {
        composerMessageHelper.markAsRead()
    }

    func updateEO(
        expirationTime: TimeInterval,
        password: String,
        passwordHint: String,
        completion: @escaping () -> Void
    ) {
        composerMessageHelper.updateExpirationOffset(expirationTime: expirationTime,
                                                     password: password,
                                                     passwordHint: passwordHint,
                                                     completion: completion)
    }

    func sendMessage(deliveryTime: Date?) {
        uploadPublicKeyIfNeeded { [weak self] in
            guard let self = self else { return }

            self.updateDraft()
            guard let msg = self.composerMessageHelper.getRawMessageObject() else {
                return
            }
            self.messageService.send(inQueue: msg, deliveryTime: deliveryTime)
        }
    }

    func deleteAttachment(_ attachment: AttachmentEntity) -> Promise<Void> {
        self.user.usedSpace(minus: attachment.fileSize.int64Value)
        return Promise { seal in
            composerMessageHelper.deleteAttachment(attachment) {
                self.updateDraft()
                seal.fulfill_()
            }
        }
    }

    func updateAddressID(_ addressId: String) -> Promise<Void> {
        return Promise { [weak self] seal in
            guard self?.composerMessageHelper.draft != nil else {
                let error = NSError(domain: "",
                                    code: -1,
                                    localizedDescription: LocalString._error_no_object)
                seal.reject(error)
                return
            }
            if self?.user.userInfo.userAddresses
                .contains(where: { $0.addressID == addressId }) == true {
                composerMessageHelper.updateAddressID(addressID: addressId) {
                    seal.fulfill_()
                }
            } else {
                let error = NSError(domain: "",
                                    code: -1,
                                    localizedDescription: LocalString._error_no_object)
                seal.reject(error)
            }
        }
    }

    func setSubject(_ sub: String) {
        self.subject = sub
    }

    func setBody(_ body: String) {
        self.body = body
    }

    func addToContacts(_ contacts: ContactPickerModelProtocol) {
        toSelectedContacts.append(contacts)
    }

    func addCcContacts(_ contacts: ContactPickerModelProtocol) {
        ccSelectedContacts.append(contacts)
    }

    func addBccContacts(_ contacts: ContactPickerModelProtocol) {
        bccSelectedContacts.append(contacts)
    }

    func collectDraft(_ title: String,
                      body: String,
                      expir: TimeInterval,
                      pwd: String,
                      pwdHit: String) {
        self.subject = title

        guard let sendAddress = getDefaultSendAddress() else {
            return
        }

        composerMessageHelper.collectDraft(recipientList: self.toJsonString(self.toSelectedContacts),
                                           bccList: self.toJsonString(self.bccSelectedContacts),
                                           ccList: self.toJsonString(self.ccSelectedContacts),
                                           sendAddress: sendAddress,
                                           title: self.subject,
                                           body: body,
                                           expiration: expir,
                                           password: pwd,
                                           passwordHint: pwdHit)
    }
}

extension ComposeViewModel {
    func htmlSignature() -> String {
        var signature = self.getDefaultSendAddress()?.signature ?? self.user.userDefaultSignature
        signature = signature.ln2br()

        var mobileSignature = self.user.showMobileSignature ?
        "<div id=\"protonmail_mobile_signature_block\"><div>\(self.user.mobileSignature)</div></div>" : ""
        mobileSignature = mobileSignature.ln2br()

        let defaultSignature = self.user.defaultSignatureStatus ?
        "<div><br></div><div><br></div><div id=\"protonmail_signature_block\"  class=\"protonmail_signature_block\"><div>\(signature)</div></div>" : ""
        let mobileBr = defaultSignature.isEmpty ?
        "<div><br></div><div><br></div>" : "<div class=\"signature_br\"><br></div><div class=\"signature_br\"><br></div>"
        let signatureHtml = "\(defaultSignature) \(mobileBr) \(mobileSignature)"
        return signatureHtml
    }

    func shouldShowExpirationWarning(havingPGPPinned: Bool,
                                     isPasswordSet: Bool,
                                     havingNonPMEmail: Bool) -> Bool {
        let helper = ComposeViewControllerHelper()
        return helper.shouldShowExpirationWarning(havingPGPPinned: havingPGPPinned,
                                                  isPasswordSet: isPasswordSet,
                                                  havingNonPMEmail: havingNonPMEmail)
    }

    func parse(mailToURL: URL) {
        guard let mailToData = mailToURL.parseMailtoLink() else { return }

        mailToData.to.forEach { recipient in
            self.addToContacts(ContactVO(name: recipient, email: recipient))
        }

        mailToData.cc.forEach { recipient in
            self.addCcContacts(ContactVO(name: recipient, email: recipient))
        }

        mailToData.bcc.forEach { recipient in
            self.addBccContacts(ContactVO(name: recipient, email: recipient))
        }

        if let subject = mailToData.subject {
            self.setSubject(subject)
        }

        if let body = mailToData.body {
            self.setBody(body)
        }
    }

    func validateAttachmentsSize(withNew data: Data) -> Bool {
        return self.currentAttachmentsSize + data.dataSize < Constants.kDefaultAttachmentFileSize
    }

    private func using12hClockFormat() -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let dateString = formatter.string(from: Date())
        let IsAmRangeNil = dateString.range(of: formatter.amSymbol) == nil
        let IsPmRangeNil = dateString.range(of: formatter.pmSymbol) == nil

        return !(IsAmRangeNil && IsPmRangeNil)
    }
}

// MARK: - Contact related methods

extension ComposeViewModel {
    /**
     Load the contacts and groups back for the message

     contact group only shows up in draft, so the reply, reply all, etc., no contact group will show up
     */
    private func updateContacts(_ origFromSent: Bool) {
        if let draft = composerMessageHelper.draft {
            switch messageAction {
            case .newDraft, .forward, .newDraftFromShare:
                break
            case .openDraft:
                let toContacts = self.toContacts(draft.recipientList) // Json to contact/group objects
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

                let ccContacts = self.toContacts(draft.ccList)
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

                let bccContacts = self.toContacts(draft.bccList)
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
                    let toContacts = self.toContacts(draft.recipientList)
                    for cont in toContacts {
                        self.toSelectedContacts.append(cont)
                    }
                } else {
                    var senders: [ContactPickerModelProtocol] = []
                    let replytos = self.toContacts(draft.replyTos)
                    if !replytos.isEmpty {
                        senders += replytos
                    } else {
                        if let newSender = self.toContact(draft.sender) {
                            senders.append(newSender)
                        } else {
                            // ignore
                        }
                    }
                    self.toSelectedContacts.append(contentsOf: senders)
                }
            case .replyAll:
                if origFromSent {
                    self.toContacts(draft.recipientList).forEach { self.toSelectedContacts.append($0) }
                    self.toContacts(draft.ccList).forEach { self.ccSelectedContacts.append($0) }
                    self.toContacts(draft.bccList).forEach { self.bccSelectedContacts.append($0) }
                } else {
                    let userAddress = self.user.addresses
                    var senders = [ContactPickerModelProtocol]()
                    let replytos = self.toContacts(draft.replyTos)
                    if !replytos.isEmpty {
                        senders += replytos
                    } else {
                        if let newSender = self.toContact(draft.sender) {
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

                    let toContacts = self.toContacts(draft.recipientList)
                    for cont in toContacts {
                        if let cont = cont as? ContactVO,
                           !cont.isDuplicated(userAddress), !cont.isDuplicatedWithContacts(self.toSelectedContacts) {
                            self.toSelectedContacts.append(cont)
                        }
                    }
                    if self.toSelectedContacts.isEmpty {
                        self.toSelectedContacts.append(contentsOf: senders)
                    }

                    self.toContacts(draft.ccList).compactMap { $0 as? ContactVO }
                        .filter { !$0.isDuplicated(userAddress) && !$0.isDuplicatedWithContacts(self.toSelectedContacts) }
                        .forEach { self.ccSelectedContacts.append($0) }
                    self.toContacts(draft.bccList).compactMap { $0 as? ContactVO }
                        .filter { !$0.isDuplicated(userAddress) && !$0.isDuplicatedWithContacts(self.toSelectedContacts) }
                        .forEach { self.bccSelectedContacts.append($0) }
                }
            }
        }
    }

    /**
     Encode the recipient information in Contact and ContactGroupVO objects
     into JSON request format (for the message object in the API)

     Currently, the fields required in the message object are: Group, Address, and Name
     */
    func toJsonString(_ contacts: [ContactPickerModelProtocol]) -> String {
        let out: [EncodableRecipient] = contacts.flatMap { contact in
            switch contact.modelType {
            case .contact:
                let contact = contact as! ContactVO
                let recipient = EncodableRecipient(address: contact.email, group: nil)
                return [recipient]
            case .contactGroup:
                let contactGroup = contact as! ContactGroupVO

                // load selected emails from the contact group
                return contactGroup.getSelectedEmailsWithDetail()
            }
        }

        do {
            let bytes = try JSONEncoder().encode(out)
            return String(bytes: bytes, encoding: .utf8)!
        } catch {
            fatalError("\(error)")
        }
    }

    /**
     Decode the recipient information in Message Object from API
     into Contact and ContactGroupVO objects
     */
    func toContacts(_ json: String) -> [ContactPickerModelProtocol] {
        guard !json.isEmpty else {
            return []
        }

        var out: [ContactPickerModelProtocol] = []
        var groups = [String: [DraftEmailData]]() // [groupName: [DraftEmailData]]

        let jsonData = Data(json.utf8)

        do {
            let recipients = try JSONDecoder().decode([DecodableRecipient].self, from: jsonData)

            for recipient in recipients {
                let name = displayNameForRecipient(recipient)

                if let group = recipient.group, !group.isEmpty {
                    // contact group
                    let toInsert = DraftEmailData(name: name, email: recipient.address)
                    if var data = groups[group] {
                        data.append(toInsert)
                        groups.updateValue(data, forKey: group)
                    } else {
                        groups.updateValue([toInsert], forKey: group)
                    }
                } else {
                    // contact
                    out.append(ContactVO(name: name, email: recipient.address))
                }
            }

            // finish parsing contact groups
            for group in groups {
                let contactGroup = ContactGroupVO(ID: "", name: group.key)
                contactGroup.overwriteSelectedEmails(with: group.value)
                out.append(contactGroup)
            }
        } catch {
            assertionFailure("\(error)")
        }
        return out
    }

    /// Provides the display name for the recipient according to https://jira.protontech.ch/browse/MAILIOS-3027
    private func displayNameForRecipient(_ recipient: DecodableRecipient) -> String {
        if let email = dependencies.contactProvider.getEmailsByAddress([recipient.address], for: user.userID).first {
            return email.contactName
        } else if let backendName = recipient.name, !backendName.replacingOccurrences(of: " ", with: "").isEmpty {
            return backendName
        } else {
            return recipient.address
        }
    }

    func toContact(_ json: String) -> ContactVO? {
        var out: ContactVO?
        let recipients: [String: String] = self.parse(json)

        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""

        if !address.isEmpty {
            out = ContactVO(name: name, email: address)
        }
        return out
    }


    private func parse(_ json: String) -> [String: String] {
        if json.isEmpty {
            return ["": ""]
        }
        do {
            let data: Data! = json.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data,
                                                           options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: String]
            return decoded ?? ["": ""]
        } catch {}
        return ["": ""]
    }

    private func makeContactPGPTypeHelper(localContacts: [PreContact]) -> ContactPGPTypeHelper {
        return ContactPGPTypeHelper(
            internetConnectionStatusProvider: dependencies.internetStatusProvider,
            apiService: user.apiService,
            userSign: user.userInfo.sign,
            localContacts: localContacts,
            userAddresses: user.addresses
        )
    }

    func lockerCheck(model: ContactPickerModelProtocol, progress: () -> Void, complete: ((UIImage?, Int) -> Void)?) {
        if model as? ContactGroupVO != nil {
            complete?(nil, -1)
            return
        }

        progress()

        guard let contactVO = model as? ContactVO else {
            complete?(nil, -1)
            return
        }
        guard let email = model.displayEmail else {
            complete?(nil, -1)
            return
        }

        dependencies
            .fetchAndVerifyContacts
            .callbackOn(.main)
            .execute(params: .init(emailAddresses: [email])) { [weak self] result in
                guard
                    let self = self,
                    let draft = self.composerMessageHelper.draft,
                    let preContacts = try? result.get()
                else {
                    complete?(nil, 0)
                    return
                }
                let contactPGPTypeHelper = self.makeContactPGPTypeHelper(localContacts: preContacts)
                let isMessageHavingPwd = draft.password != .empty

                contactPGPTypeHelper.calculateEncryptionIcon(
                    email: email,
                    isMessageHavingPWD: isMessageHavingPwd
                ) { [weak self] iconStatus, errorCode in
                    contactVO.encryptionIconStatus = iconStatus
                    complete?(iconStatus?.iconWithColor, errorCode ?? 0)
                    if errorCode != nil, let errorString = iconStatus?.text {
                        self?.showError?(errorString)
                    }
                }
            }
    }

    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?) {
        progress()
        let emails = contactGroup.getSelectedEmailData().map { $0.email }
        let isMessageHavingPwd = composerMessageHelper.draft?.password != .empty

        dependencies.fetchAndVerifyContacts.execute(params: .init(emailAddresses: emails)) { [weak self] result in
            guard let self = self, let preContacts = try? result.get() else {
                complete?(nil, -1)
                return
            }
            let contactPGPTypeHelper = self.makeContactPGPTypeHelper(localContacts: preContacts)

            var firstErrorCode: Int?
            let group = DispatchGroup()
            for email in emails {
                group.enter()
                contactPGPTypeHelper.calculateEncryptionIcon(
                    email: email,
                    isMessageHavingPWD: isMessageHavingPwd
                ) { iconStatus, errCode in
                    if firstErrorCode == nil { firstErrorCode = errCode }
                    if let iconStatus = iconStatus {
                        contactGroup.update(mail: email, iconStatus: iconStatus)
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) { [weak self] in
                if let errorCode = firstErrorCode {
                    self?.showToastIfNeeded(errorCode: errorCode)
                    complete?(nil, errorCode)
                } else {
                    complete?(nil, 0)
                }
            }
        }
    }

    func embedInlineAttachments(in htmlEditor: HtmlEditorBehaviour) {
        guard let attachments = getAttachments() else { return }
        let inlineAttachments = attachments
            .filter({ attachment in
                guard let contentId = attachment.contentId else { return false }
                return !contentId.isEmpty && attachment.isInline
            })
        let userKeys = user.toUserKeys()

        for att in inlineAttachments {
            guard let contentId = att.contentId else { continue }
            dependencies.fetchAttachment.callbackOn(.main).execute(
                params: .init(
                    attachmentID: att.id,
                    attachmentKeyPacket: att.keyPacket,
                    purpose: .decryptAndEncodeAttachment,
                    userKeys: userKeys
                )
            ) { result in
                guard let base64Att = try? result.get().encoded, !base64Att.isEmpty else {
                    return
                }
                htmlEditor.update(embedImage: "cid:\(contentId)", encoded:"data:\(att.rawMimeType);base64,\(base64Att)")
            }
        }
    }

    func isDraftHavingEmptyRecipient() -> Bool {
        return toSelectedContacts.isEmpty &&
        ccSelectedContacts.isEmpty &&
        bccSelectedContacts.isEmpty
    }

    func doesInvalidAddressExist() -> Bool {
        let allContacts = toSelectedContacts + ccSelectedContacts + bccSelectedContacts
        let invalidEmails = allContacts
            .filter { $0.modelType == .contact }
            .compactMap { $0 as? ContactVO }
            .filter {
                $0.encryptionIconStatus?.nonExisting == true ||
                $0.encryptionIconStatus?.isInvalid == true
            }
        return !invalidEmails.isEmpty
    }

    func shouldShowScheduleSendConfirmationAlert() -> Bool {
        return isEditingScheduleMsg && deliveryTime == nil
	}

    func fetchContacts() {
        let service = user.contactService
        emailsController = service.makeAllEmailsFetchedResultController()
        emailsController?.delegate = self
        try? emailsController?.performFetch()
        let allContacts = (emailsController?.fetchedObjects ?? [])
            .map { email in
                ContactVO(
                    name: email.name,
                    email: email.email,
                    isProtonMailContact: true
                )
            }
        // Remove the duplicated items
        var set = Set<ContactVO>()
        var filteredResult = [ContactVO]()
        for contact in allContacts {
            if !set.contains(contact) {
                set.insert(contact)
                filteredResult.append(contact)
            }
        }
        self.contacts = filteredResult
    }

    func fetchPhoneContacts(completion: (() -> Void)?) {
        let service = user.contactService
        service.getContactVOsFromPhone { contacts, error in
            self.phoneContacts = contacts
            completion?()
        }
    }

    func addContactWithPhoneContact() {
        var contactsWithoutLastTimeUsed: [ContactPickerModelProtocol] = phoneContacts

        if user.hasPaidMailPlan {
            let contactGroupsToAdd = user.contactGroupService.getAllContactGroupVOs().filter {
                $0.contactCount > 0
            }
            contactsWithoutLastTimeUsed.append(contentsOf: contactGroupsToAdd)
        }
        // sort the contact group and phone address together
        contactsWithoutLastTimeUsed.sort(by: { $0.contactTitle.lowercased() < $1.contactTitle.lowercased() })

        self.contacts += contactsWithoutLastTimeUsed
    }
}

extension ComposeViewModel {
    struct Dependencies {
        let fetchAndVerifyContacts: FetchAndVerifyContactsUseCase
        let internetStatusProvider: InternetConnectionStatusProvider
        let fetchAttachment: FetchAttachmentUseCase
        let contactProvider: ContactProviderProtocol

        init(
            fetchAndVerifyContacts: FetchAndVerifyContactsUseCase,
            internetStatusProvider: InternetConnectionStatusProvider,
            fetchAttachment: FetchAttachmentUseCase,
            contactProvider: ContactProviderProtocol
        ) {
            self.fetchAndVerifyContacts = fetchAndVerifyContacts
            self.internetStatusProvider = internetStatusProvider
            self.fetchAttachment = fetchAttachment
            self.contactProvider = contactProvider
        }
    }

    struct EncodableRecipient: Encodable {
        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case group = "Group"
        }

        let address: String
        let group: String?
    }

    struct DecodableRecipient: Decodable {
        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case group = "Group"
            case name = "Name"
        }

        let address: String
        let group: String?
        let name: String?
    }
}

extension ComposeViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let emails = controller.fetchedObjects as? [Email] else {
            return
        }
        let allContacts = emails.map { email in
            ContactVO(
                name: email.name,
                email: email.email,
                isProtonMailContact: true
            )
        }
        // Remove the duplicated items
        var set = Set<ContactVO>()
        var filteredResult = [ContactVO]()
        for contact in allContacts {
            if !set.contains(contact) {
                set.insert(contact)
                filteredResult.append(contact)
            }
        }
        self.contacts = filteredResult
    }
}
