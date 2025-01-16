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

import Combine
import CoreData
import Foundation
import PromiseKit
import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreNetworking
import ProtonMailAnalytics
import SwiftSoup

// sourcery: mock
protocol ComposeUIProtocol: AnyObject {
    func changeInvalidSenderAddress(to newAddress: Address)
    func updateSenderAddressesList()
    func show(error: String)
}

class ComposeViewModel: NSObject {
    /// Only to notify ComposeContainerViewModel that contacts changed
    @objc private(set) dynamic var contactsChange: Int = 0
    @objc dynamic var contentHeight: CGFloat = 0.1

    let user: UserManager
    /// Only use in share extension, to record if the share items over 25 mb or not
    private(set) var shareOverLimitationAttachment = false
    let composerMessageHelper: ComposerMessageHelper
    let messageService: MessageDataService
    let isEditingScheduleMsg: Bool
    let originalScheduledTime: Date?
    let dependencies: Dependencies
    var urlSchemesToBeHandle: Set<String> {
        let schemes: [HTTPRequestSecureLoader.ProtonScheme] = [.http, .https, .noProtocol]
        return Set(schemes.map(\.rawValue))
    }

    var contacts: [ContactPickerModelProtocol] {
        // sort the contact group and phone address together
        let sortedContacts = phoneContacts.appending(protonGroupContacts).sorted(by: { $0.contactTitle.lowercased() < $1.contactTitle.lowercased() })
        return protonContacts + sortedContacts
    }
    private var phoneContacts: [ContactPickerModelProtocol] = [] {
        didSet {
            contactsDidChangePublisher.send()
        }
    }
    private var protonContacts: [ContactPickerModelProtocol] = [] {
        didSet {
            contactsDidChangePublisher.send()
        }
    }
    private var protonGroupContacts: [ContactPickerModelProtocol] = []
    private var emailPublisher: EmailPublisher?
    private var cancellable: AnyCancellable?

    private(set) var messageAction: ComposeMessageAction = .newDraft
    private(set) var subject: String = .empty
    var body: String = .empty
    var deliveryTime: Date?
    private var importedFiles: [FileData] = []
    weak var uiDelegate: ComposeUIProtocol?
    private var originalSender: ContactVO?
    private let preferredRemoteContentPolicy: WebContents.RemoteContentPolicy
    private let preferredEmbeddedContentPolicy: WebContents.EmbeddedContentPolicy

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

    var shouldStripMetaData: Bool {
        dependencies.keychain[.metadataStripping] == .stripMetadata
    }

    let contactsDidChangePublisher = PassthroughSubject<Void, Never>()

    // For share extension
    init(
        subject: String,
        body: String,
        files: [FileData],
        action: ComposeMessageAction,
        originalScheduledTime: Date? = nil,
        dependencies: Dependencies
    ) {
        self.user = dependencies.user
        messageService = dependencies.user.messageService
        self.isEditingScheduleMsg = false

        // We have dependencies as an optional input parameter to avoid making
        // a huge refactor but allowing the dependencies injection open for testing.
        self.dependencies = dependencies

        composerMessageHelper = ComposerMessageHelper(dependencies: self.dependencies.helperDependencies, user: user)

        self.subject = subject
        self.body = body
        self.messageAction = action
        self.originalScheduledTime = originalScheduledTime
        self.importedFiles = files
        self.preferredRemoteContentPolicy = dependencies.user.userInfo.hideRemoteImages == 1 ? .disallowed : .allowedWithoutProxy
        self.preferredEmbeddedContentPolicy = dependencies.user.userInfo.hideEmbeddedImages == 1 ? .disallowed : .allowed
        super.init()

        self.collectDraft(subject,
                          body: body,
                          expir: 0,
                          pwd: "",
                          pwdHit: "")
        self.updateDraft()
        checkImportedFilesSize()
    }

    init(
        isEditingScheduleMsg: Bool = false,
        originalScheduledTime: Date? = nil,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy,
        dependencies: Dependencies
    ) {
        self.user = dependencies.user
        self.preferredRemoteContentPolicy = remoteContentPolicy
        self.preferredEmbeddedContentPolicy = embeddedContentPolicy
        messageService = dependencies.user.messageService
        self.isEditingScheduleMsg = isEditingScheduleMsg
        self.originalScheduledTime = originalScheduledTime
        self.dependencies = dependencies

        composerMessageHelper = ComposerMessageHelper(dependencies: self.dependencies.helperDependencies, user: user)

        super.init()
    }

    func initialize(message msg: MessageEntity?, action: ComposeMessageAction) throws {
        var mimeAttachmentsShouldBeAdded: [MimeAttachment]?
        if let msg {
            if msg.isDraft {
                self.composerMessageHelper.setNewMessage(objectID: msg.objectID.rawValue)
            } else {
                mimeAttachmentsShouldBeAdded = try composerMessageHelper.copyAndCreateDraft(from: msg.messageID, action: action)
            }
        }

        self.subject = self.composerMessageHelper.draft?.title ?? ""
        self.messageAction = action

        // get original message if from sent
        let fromSent: Bool = msg?.isSent ?? false
        self.updateContacts(fromSent)
        originalSender = composerMessageHelper.draft?.senderVO
        initializeSenderAddress()
        observeAddressStatusChangedEvent()

        // Create the draft before the attachment upload because we need the messageID ready.
        composerMessageHelper.uploadDraft()

        if let mimeAttachments = mimeAttachmentsShouldBeAdded {
            let stripMetaData = dependencies.keychain[.metadataStripping] == .stripMetadata
            for mimeAttachment in mimeAttachments {
                composerMessageHelper.addMimeAttachments(
                    attachment: mimeAttachment,
                    shouldStripMetaData: stripMetaData,
                    completion: { _ in })
            }
        }
    }

    private func showToastIfNeeded(errorCode: Int) {
        if errorCode == PGPTypeErrorCode.recipientNotFound.rawValue {
            LocalString._address_in_group_not_found_error.alertToast()
        }
    }

    func getCurrentSignature(_ addressId: String) -> String? {
        if let addr = self.user.userInfo.userAddresses.address(byID: addressId) {
            return addr.signature
        }
        return nil
    }

    // check if has external emails and if need attach key
    private func uploadPublicKeyIfNeeded() throws {
        let userinfo = self.user.userInfo
        
        guard userinfo.attachPublicKey == 1 ||
                (composerMessageHelper.getMessageEntity()?.flag.contains(.publicKey) ?? false ) else {
            return
        }

        guard let draft = self.composerMessageHelper.draft,
              let addr = self.messageService.defaultUserAddress(of: draft.sendAddressID),
              let key = addr.keys.first else {
            return
        }

        let data = Data(key.publicKey.utf8)

        _ = try composerMessageHelper.addPublicKeyIfNeeded(
            email: addr.email,
            fingerprint: key.shortFingerprint,
            data: data,
            shouldStripMetaDate: shouldStripMetaData
        )
    }

    func loadingPolicy() -> (WebContents.LoadingType, WebContents.RemoteContentPolicy) {
        let isImageProxyEnabled = user.userInfo.imageProxy.contains(.imageProxy)
        let contentLoadingType: WebContents.LoadingType = isImageProxyEnabled ? .proxy : .skipProxy
        var remoteContentMode: WebContents.RemoteContentPolicy = preferredRemoteContentPolicy
        if remoteContentMode == .allowedThroughProxy && !isImageProxyEnabled {
            remoteContentMode = .allowedWithoutProxy
        } else if remoteContentMode == .allowedWithoutProxy && isImageProxyEnabled {
            remoteContentMode = .allowedThroughProxy
        }
        return (contentLoadingType, remoteContentMode)
    }

    func getHtmlBody() -> WebContents {
        let (contentLoadingType, remoteContentMode) = loadingPolicy()

        let head = "<html><head></head><body>"
        let foot = "</body></html>"
        let signatureHtml = self.htmlSignature()

        switch messageAction {
        case .openDraft:
            let body = decryptedBody()
            let supplementCSS = supplementCSS(from: body)
            return .init(
                body: body,
                remoteContentMode: remoteContentMode,
                messageDisplayMode: .expanded,
                contentLoadingType: contentLoadingType,
                supplementCSS: supplementCSS
            )
        case .reply, .replyAll:
            let msg = composerMessageHelper.draft!
            let body = decryptedBody()

            let clockFormat: String = using12hClockFormat() ? Constants.k12HourMinuteFormat : Constants.k24HourMinuteFormat
            let timeFormat = String.localizedStringWithFormat(LocalString._reply_time_desc, clockFormat)
            let timeDesc: String = msg.originalTime?.formattedWith(timeFormat) ?? ""
            let senderName: String = originalSender?.name ?? "unknown"
            let senderEmail: String = originalSender?.email ?? "unknown"

            var replyHeader = "\(timeDesc), \(senderName)"
            replyHeader.append(contentsOf: " &lt;<a href=\"mailto:")
            replyHeader.append(contentsOf: "\(replyHeader)\(senderName)\" class=\"\">\(senderEmail)</a>&gt;")

            let w = LocalString._composer_wrote
            let sp = "<div><br></div><div><br></div>\(replyHeader) \(w)</div><blockquote class=\"protonmail_quote\" type=\"cite\"> "

            let result = " \(head) \(signatureHtml) \(sp) \(body)</blockquote>\(foot)"
            let supplementCSS = supplementCSS(from: result)
            return .init(
                body: result,
                remoteContentMode: remoteContentMode,
                messageDisplayMode: .expanded,
                contentLoadingType: contentLoadingType,
                supplementCSS: supplementCSS
            )
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
            let senderName: String = originalSender?.name ?? .empty
            let senderEmail: String = originalSender?.email ?? .empty

            var forwardHeader =
                "---------- \(fwdm) ----------<br>\(from) \(senderName) &lt;<a href=\"mailto:\(senderEmail)\" class=\"\">\(senderEmail)"
            forwardHeader.append(contentsOf: "</a>&gt;<br>\(dt) \(timeDesc)<br>\(sj) \(msg.title)<br>")

            if !msg.recipientList.isEmpty {
                forwardHeader.append(contentsOf: "\(t) \(msg.recipientList.formatJsonContact(true))<br>")
            }

            if !msg.ccList.isEmpty {
                forwardHeader.append(contentsOf: "\(c) \(msg.ccList.formatJsonContact(true))<br>")
            }
            let body = decryptedBody()

            let sp = "<div><br></div><div><br></div><blockquote class=\"protonmail_quote\" type=\"cite\">\(forwardHeader)</div> "
            let result = "\(head)\(signatureHtml)\(sp)\(body)\(foot)"

            let supplementCSS = supplementCSS(from: result)
            return .init(
                body: result,
                remoteContentMode: remoteContentMode,
                messageDisplayMode: .expanded,
                contentLoadingType: contentLoadingType,
                supplementCSS: supplementCSS
            )
        case .newDraft:
            if !self.body.isEmpty {
                let newHTMLString = "\(head) \(self.body) \(signatureHtml) \(foot)"
                self.body = ""
                return .init(
                    body: newHTMLString,
                    remoteContentMode: remoteContentMode,
                    messageDisplayMode: .expanded,
                    contentLoadingType: contentLoadingType
                )
            }
            let body: String = signatureHtml.trim().isEmpty ? .empty : signatureHtml
            let supplementCSS = supplementCSS(from: body)
            return .init(
                body: body,
                remoteContentMode: remoteContentMode,
                messageDisplayMode: .expanded,
                contentLoadingType: contentLoadingType,
                supplementCSS: supplementCSS
            )
        case .newDraftFromShare:
            if !self.body.isEmpty {
                let newHTMLString = """
                \(head) \(self.body.ln2br()) \(signatureHtml) \(foot)
                """

                return .init(
                    body: newHTMLString,
                    remoteContentMode: remoteContentMode,
                    messageDisplayMode: .expanded,
                    contentLoadingType: contentLoadingType
                )
            } else if signatureHtml.trim().isEmpty {
                // add some space
                let defaultBody = "<div><br></div><div><br></div><div><br></div><div><br></div>"
                return .init(
                    body: defaultBody,
                    remoteContentMode: remoteContentMode,
                    messageDisplayMode: .expanded,
                    contentLoadingType: contentLoadingType
                )
            }
            return .init(
                body: signatureHtml,
                remoteContentMode: remoteContentMode,
                messageDisplayMode: .expanded,
                contentLoadingType: contentLoadingType
            )
        }
    }

    private func decryptedBody() -> String {
        let rawHTML = composerMessageHelper.decryptBody()

        do {
            let document: Document = try Parser.parseAndLogErrors(rawHTML)
            if let body = document.body() {
                return try body.html()
            } else {
                return try document.html()
            }
        } catch {
            SystemLogger.log(error: error)
            return rawHTML
        }
    }

    private func supplementCSS(from html: String) -> String? {
        var supplementCSS: String?
        let document = CSSMagic.parse(htmlString: html)
        if CSSMagic.darkStyleSupportLevel(
            document: document, 
            sender: "",
            darkModeStatus: dependencies.userDefaults[.darkModeStatus]
        ) == .protonSupport {
            supplementCSS = CSSMagic.generateCSSForDarkMode(document: document)
        }
        return supplementCSS
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

            let isBodyTextEmpty = (body?.isEmpty ?? false) || body == signature
            let noImages = (try? bodyDocument?.body()?.select("img").isEmpty()) ?? true

            return isBodyTextEmpty && noImages
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
        messageService.deleteDraft(message: rawMessage)
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

    func sendMessage(deliveryTime: Date?) throws {
        SystemLogger.log(message: "Preparing to send", category: .sendMessage)

        try uploadPublicKeyIfNeeded()

        SystemLogger.log(message: "Public key prepared", category: .sendMessage)

        updateDraft()
        guard let msg = composerMessageHelper.getMessageEntity() else {
            return
        }

        SystemLogger.log(message: "Message prepared", category: .sendMessage)

        try messageService.send(inQueue: msg, deliveryTime: deliveryTime)
    }

    // Exact base64 image from body and upload it, if has any
    func extractAndUploadBase64ImagesFromSendingBody(body: String) -> String {
        guard
            let document = Parser.parseAndLogErrors(body),
            let base64Images = try? document.select(#"img[src^="data"]"#)
        else {
            return body
        }
        for image in base64Images {
            let cid = "\(String.randomString(8))@pm.me"
            guard
                let src = try? image.attr("src"),
                let (type, _, base64) = MIMEEMLBuilder.extractInformation(from: src),
                let _ = try? image.attr("src", "cid:\(cid)"),
                let data = Data(base64Encoded: base64.encoded)
            else { continue }

            do {
                _ = try composerMessageHelper.addAttachment(
                    data: data,
                    fileName: cid,
                    shouldStripMetaData: true,
                    type: type,
                    isInline: true,
                    cid: cid
                )
            } catch {
                SystemLogger.log(error: error, category: .draft)
            }
        }
        document.outputSettings().prettyPrint(pretty: false)
        guard let cleanBody = try? document.html() else { return body }
        return cleanBody
    }

    func deleteAttachment(_ attachment: AttachmentEntity, caller: StaticString = #function) -> Promise<Void> {
        SystemLogger.log(message: "CVM deleteAttachment called by \(caller)", category: .draft)
        self.user.usedSpace(minus: attachment.fileSize.int64Value)
        return Promise { seal in
            composerMessageHelper.deleteAttachment(attachment) {
                self.updateDraft()
                seal.fulfill_()
            }
        }
    }

    func updateAddress(
        to address: Address,
        uploadDraft: Bool = true,
        completion: @escaping (Swift.Result<Void, NSError>) -> Void
    ) {
        guard composerMessageHelper.draft != nil else {
            let error = NSError(
                domain: "",
                code: -1,
                localizedDescription: LocalString._error_no_object
            )
            completion(.failure(error))
            return
        }
        guard !composerMessageHelper.attachments.contains(where: { $0.id.rawValue == "0" }) else {
            let error = NSError(
                domain: "",
                code: -1,
                localizedDescription: L10n.Compose.blockSenderChangeMessage
            )
            completion(.failure(error))
            return
        }
        if user.userInfo.userAddresses.contains(where: { $0.addressID == address.addressID }) {
            composerMessageHelper.updateAddress(to: address, uploadDraft: uploadDraft) {
                completion(.success(()))
            }
        } else {
            let error = NSError(
                domain: "",
                code: -1,
                localizedDescription: LocalString._error_no_object
            )
            completion(.failure(error))
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

        guard let sendAddress = currentSenderAddress() else {
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

// MARK: - Attachments
extension ComposeViewModel {
    func getAttachments() -> [AttachmentEntity] {
        return composerMessageHelper.attachments
            .filter { !$0.isSoftDeleted }
            .sorted(by: { $0.order < $1.order })
    }

    func needAttachRemindAlert(
        subject: String,
        body: String
    ) -> Bool {
        // If the message contains attachments
        // It contains keywords or not doesn't important
        guard composerMessageHelper.draft?.attachments.isEmpty ?? true else { return false }

        let content = "\(subject) \(body.body(strippedFromQuotes: true))"
        let language = LanguageManager().currentLanguageCode()
        return AttachReminderHelper.hasAttachKeyword(content: content, language: language)
    }

    func validateAttachmentsSize(withNew data: Data) -> Bool {
        return self.currentAttachmentsSize + data.dataSize < Constants.kDefaultAttachmentFileSize
    }

    func embedInlineAttachments(in htmlEditor: HtmlEditorBehaviour) {
        guard preferredEmbeddedContentPolicy == .allowed else { return }
        let attachments = getAttachments()
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
                    userKeys: userKeys
                )
            ) { result in
                guard let base64Att = try? result.get().data.base64EncodedString(), !base64Att.isEmpty else {
                    return
                }
                htmlEditor.update(embedImage: "cid:\(contentId)", encoded:"data:\(att.rawMimeType);base64,\(base64Att)")
            }
        }
    }

    // Check if the shared files over size limitation
    func checkImportedFilesSize() {
        var currentAttachmentSize = 0
        for file in importedFiles {
            let size = file.contents.dataSize
            guard size < (Constants.kDefaultAttachmentFileSize - currentAttachmentSize) else {
                self.shareOverLimitationAttachment = true
                break
            }
            currentAttachmentSize += size
        }
    }

    // Insert shared files
    // For images, insert as inlines
    // For others, insert as normal attachment
    func insertImportedFiles(in htmlEditor: HtmlEditorBehaviour) {
        for file in importedFiles {
            if (AttachmentType.mimeTypeMap[.image] ?? []).contains(file.mimeType.lowercased()) {
                insertImportedImage(file: file, in: htmlEditor)
            } else {
                attachImported(file: file)
            }
        }
    }

    private func insertImportedImage(file: FileData, in htmlEditor: HtmlEditorBehaviour) {
        guard let url = file.contents as? URL, let base64String = url.toBase64() else {
            PMAssertionFailure("can't get base64")
            return
        }
        composerMessageHelper.addAttachment(
            file,
            shouldStripMetaData: shouldStripMetaData,
            isInline: true
        ) { attachment in
            guard let attachment = attachment, let contentID = attachment.contentId else { return }
            let encodedData = "data:\(file.mimeType);base64, \(base64String)"
            htmlEditor.insertEmbedImage(cid: "cid:\(contentID)", encodedData: encodedData)
        }
    }

    private func attachImported(file: FileData) {
        composerMessageHelper.addAttachment(
            file,
            shouldStripMetaData: shouldStripMetaData,
            isInline: false
        ) { _ in
            self.updateDraft()
            self.composerMessageHelper.updateAttachmentView?()
        }
    }

    func attachInlineAttachment(inlineAttachment: AttachmentEntity, completion: ((Bool) -> Void)?) {
        dependencies.fetchAttachment.callbackOn(.main).execute(params: .init(
            attachmentID: inlineAttachment.id,
            attachmentKeyPacket: inlineAttachment.keyPacket,
            userKeys: user.toUserKeys()
        )) { result in
            guard let data = try? result.get().data, !data.isEmpty else {
                completion?(false)
                return
            }

            do {
                _ = try self.composerMessageHelper.addAttachment(
                    data: data,
                    fileName: inlineAttachment.name,
                    shouldStripMetaData: self.shouldStripMetaData,
                    type: inlineAttachment.rawMimeType,
                    isInline: false
                )
                completion?(true)
            } catch {
                SystemLogger.log(error: error, category: .draft)
                completion?(false)
            }
        }
    }
}

// MARK: - Address
extension ComposeViewModel {
    private func observeAddressStatusChangedEvent() {
        dependencies.notificationCenter.addObserver(
            self,
            selector: #selector(self.addressesStatusChanged),
            name: .addressesStatusAreChanged,
            object: nil
        )
    }
    
    @objc
    private func addressesStatusChanged() {
        DispatchQueue.main.async {
            defer {
                self.uiDelegate?.updateSenderAddressesList()
            }
            switch self.messageAction {
            case .forward, .reply, .replyAll, .openDraft:
                guard
                    let senderAddress = self.currentSenderAddress(),
                    senderAddress.status == .disabled,
                    let validAddress = self.validSenderAddressFromMessage(),
                    validAddress.addressID != senderAddress.addressID,
                    validAddress.email != senderAddress.email
                else { return }
                self.uiDelegate?.changeInvalidSenderAddress(to: validAddress)
            case .newDraft, .newDraftFromShare:
                guard
                    let senderAddress = self.currentSenderAddress(),
                    senderAddress.status == .disabled,
                    let defaultAddress = self.user.addresses.defaultSendAddress()
                else { return }
                self.uiDelegate?.changeInvalidSenderAddress(to: defaultAddress)
            }
        }
    }

    /// The sender address needs to be updated to a valid address
    /// Not the sender of the original message
    private func initializeSenderAddress() {
        switch messageAction {
        case .forward, .reply, .replyAll, .openDraft:
            if let address = validSenderAddressFromMessage() {
                updateAddress(to: address, uploadDraft: false) { _ in }
            }
        case .newDraft, .newDraftFromShare:
            if let address = user.addresses.defaultAddress() {
                updateAddress(to: address, uploadDraft: false) { _ in }
            }
        }
    }

    private func validSenderAddressFromMessage() -> Address? {
        let validUserAddresses = user.addresses
            .filter { $0.status == .enabled && $0.send == .active }
        var validAddress: Address?
        let referenceAddress = composerMessageHelper.originalTo() ?? composerMessageHelper.originalFrom() ?? ""
        if let address = validUserAddresses.first(where: {
            $0.email == referenceAddress
        }) {
            validAddress = address
        } else if let aliasAddress = getAddressFromPlusAlias(
            userAddress: validUserAddresses,
            originalAddress: referenceAddress
        ) {
            validAddress = aliasAddress
        } else if let draft = composerMessageHelper.draft,
                  let defaultAddress = messageService.defaultUserAddress(of: draft.sendAddressID) {
            validAddress = defaultAddress
        } else {
            validAddress = user.addresses.defaultAddress()
        }
        return validAddress
    }

    /// Original sender address based on original message information
    /// The returned address could be disabled for serval reason
    func originalSenderAddress() -> Address? {
        let referenceAddress = composerMessageHelper.originalTo() ?? composerMessageHelper.originalFrom() ?? ""
        if let address = user.addresses.first(where: { $0.email == referenceAddress }) {
            return address
        } else if let aliasAddress = getAddressFromPlusAlias(
            userAddress: user.addresses,
            originalAddress: referenceAddress
        ) {
            return aliasAddress
        }
        return nil
    }

    func currentSenderAddress() -> Address? {
        let defaultAddress = user.addresses.defaultSendAddress()
        guard
            let entity = composerMessageHelper.getMessageEntity(),
            let draft = composerMessageHelper.draft,
            let sender = try? entity.parseSender(),
            let address = user.addresses.first(where: { $0.addressID == draft.sendAddressID.rawValue })
        else { return defaultAddress }

        if address.email == sender.address {
            return address
        } else {
            return Address(
                addressID: address.addressID,
                domainID: address.domainID,
                email: sender.address,
                send: address.send,
                receive: address.receive,
                status: address.status,
                type: address.type,
                order: address.order,
                displayName: address.displayName,
                signature: address.signature,
                hasKeys: address.hasKeys,
                keys: address.keys
            )
        }
    }

    func getAddresses() -> [Address] {
        var addresses: [Address] = user.addresses
        if let referenceAddress = composerMessageHelper.originalTo() ?? composerMessageHelper.originalFrom() {
            addresses = getFromAddressList(originalTo: referenceAddress)
        }
        return addresses
            .filter { $0.status == .enabled && $0.send == .active }
            .sorted(by: { $0.order < $1.order })
    }

    private func getFromAddressList(originalTo: String?) -> [Address] {
        var validUserAddress = user.addresses
            .filter { $0.status == .enabled && $0.send == .active }
            .sorted(by: { $0.order >= $1.order })

        if let aliasAddress = getAddressFromPlusAlias(
            userAddress: validUserAddress,
            originalAddress: originalTo ?? ""
        ) {
            validUserAddress.insert(aliasAddress, at: 0)
        }
        return validUserAddress
    }

    private func getAddressFromPlusAlias(userAddress: [Address], originalAddress: String) -> Address? {
        guard let plusIndex = originalAddress.firstIndex(of: "+"),
              let atIndex = originalAddress.firstIndex(of: "@") else { return nil }
        let normalizedAddress = originalAddress.canonicalizeEmail(scheme: .proton)
        guard let address = userAddress
            .first(where: {
                $0.email.canonicalizeEmail(scheme: .proton) == normalizedAddress
            }),
              address.email != originalAddress
        else { return nil }
        let alias = originalAddress[plusIndex..<atIndex]
        guard let atIndexInAddress = address.email.firstIndex(of: "@") else { return nil }
        var email = address.email
        email.insert(contentsOf: alias, at: atIndexInAddress)
        return Address(
            addressID: address.addressID,
            domainID: address.domainID,
            email: email,
            send: address.send,
            receive: address.receive,
            status: address.status,
            type: address.type,
            order: address.order,
            displayName: address.displayName,
            signature: address.signature,
            hasKeys: address.hasKeys,
            keys: address.keys
        )
    }
}

extension ComposeViewModel {
    func htmlSignature() -> String {
        var signature = currentSenderAddress()?.signature ?? self.user.userDefaultSignature
        signature = signature.ln2br()

        let mobileSignature = self.mobileSignature()

        let defaultSignature = self.user.defaultSignatureStatus ?
        "<div><br></div><div><br></div><div id=\"protonmail_signature_block\"  class=\"protonmail_signature_block\"><div>\(signature)</div></div>" : ""
        let mobileBr = defaultSignature.isEmpty ?
        "<div><br></div><div><br></div>" : "<div class=\"signature_br\"><br></div><div class=\"signature_br\"><br></div>"
        let signatureHtml = "\(defaultSignature) \(mobileBr) \(mobileSignature)"
        return signatureHtml
    }

    func mobileSignature() -> String {
        guard user.showMobileSignature else { return .empty }
        var userMobileSignature = dependencies.fetchMobileSignatureUseCase.execute(
            params: .init(userID: user.userID, isPaidUser: user.hasPaidMailPlan)
        )
        userMobileSignature = userMobileSignature.preg_replace(
            "Proton Mail",
            replaceto: "<a href=\"\(Link.promoteInMobilSignature)\">Proton Mail</a>"
        )

        let mobileSignature = "<div id=\"protonmail_mobile_signature_block\"><div>\(userMobileSignature)</div></div>"
            .ln2br()
        return mobileSignature
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
    private func updateContact(from jsonList: String, to selectedContacts: inout [ContactPickerModelProtocol]) {
        // Json to contact/group objects
        let parsedContacts = toContacts(jsonList)
        
        for contact in parsedContacts {
            switch contact.modelType {
            case .contact:
                guard let contact = contact as? ContactVO else {
                    PMAssertionFailure("Model type and value doesn't match when init composer recipient, \(contact.modelType)")
                    continue
                }
                if !contact.exists(in: selectedContacts) {
                    selectedContacts.append(contact)
                }
            case .contactGroup:
                guard let group = contact as? ContactGroupVO else {
                    PMAssertionFailure("Model type and value doesn't match when init composer recipient, \(contact.modelType)")
                    continue
                }
                selectedContacts.append(group)
            }
        }
    }
    /**
     Load the contacts and groups back for the message

     contact group only shows up in draft, so the reply, reply all, etc., no contact group will show up
     */
    private func updateContacts(_ origFromSent: Bool) {
        guard let draft = composerMessageHelper.draft else { return }
        switch messageAction {
        case .newDraft, .forward, .newDraftFromShare:
            break
        case .openDraft:
            updateContact(from: draft.recipientList, to: &toSelectedContacts)
            updateContact(from: draft.ccList, to: &ccSelectedContacts)
            updateContact(from: draft.bccList, to: &bccSelectedContacts)
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
                    }
                }
                self.toSelectedContacts.append(contentsOf: senders)
            }
        case .replyAll:
            if origFromSent {
                self.toContacts(draft.recipientList).forEach { self.toSelectedContacts.append($0) }
                self.toContacts(draft.ccList).forEach { self.ccSelectedContacts.append($0) }
                self.toContacts(draft.bccList).forEach { self.bccSelectedContacts.append($0) }
                return
            }

            if toContacts(draft.replyTos).isEmpty {
                updateContact(from: draft.sender, to: &toSelectedContacts)
            } else {
                updateContact(from: draft.replyTos, to: &toSelectedContacts)
            }

            let userAddress = user.addresses
            // Reply all doesn't have bcc
            let recipients = toContacts(draft.recipientList) + toContacts(draft.ccList)
            recipients
                .compactMap { $0 as? ContactVO }
                .filter { !$0.isDuplicated(userAddress) && !$0.exists(in: toSelectedContacts) }
                .forEach { ccSelectedContacts.append($0) }
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
                let recipient = EncodableRecipient(name: contact.name, address: contact.email, group: nil)
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
                let contactGroup = ContactGroupVO(
                    ID: "",
                    name: group.key,
                    contextProvider: dependencies.coreDataContextProvider
                )
                contactGroup.overwriteSelectedEmails(with: group.value)
                out.append(contactGroup)
            }
        } catch {
            if !ProcessInfo.isRunningUnitTests {
                assertionFailure("\(error)")
            }
        }
        return out
    }

    /// Provides the display name for the recipient according to https://jira.protontech.ch/browse/MAILIOS-3027
    private func displayNameForRecipient(_ recipient: DecodableRecipient) -> String {
        if let email = dependencies.contactProvider.getEmailsByAddress([recipient.address]).first {
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
            fetchEmailAddressesPublicKey: user.container.fetchEmailAddressesPublicKey,
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
                        self?.uiDelegate?.show(error: errorString)
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
        emailPublisher = .init(
            userID: user.userID,
            isContactCombine: dependencies.userDefaults[.isCombineContactOn],
            contextProvider: dependencies.coreDataContextProvider
        )
        cancellable = emailPublisher?.contentDidChange
            .map { $0.map { email in
                ContactVO(name: email.name, email: email.email, isProtonMailContact: true)
            }}
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] contactVOs in
                // Remove the duplicated items
                var set = Set<ContactVO>()
                var filteredResult = [ContactVO]()
                for contact in contactVOs {
                    if !set.contains(contact) {
                        set.insert(contact)
                        filteredResult.append(contact)
                    }
                }
                self?.protonContacts = filteredResult
            })
        emailPublisher?.start()
        fetchGroupContacts()
    }

    func fetchPhoneContacts() {
        let service = user.contactService
        service.getContactVOsFromPhone { contacts, error in
            DispatchQueue.main.async {
                self.phoneContacts = contacts
            }
        }
    }

    private func fetchGroupContacts() {
        guard user.hasPaidMailPlan else { return }
        protonGroupContacts = user.contactGroupService.getAllContactGroupVOs().filter { $0.contactCount > 0 }
    }

    func shouldShowSenderChangedAlertDueToDisabledAddress() -> Bool {
        guard let currentSenderAddress = currentSenderAddress(),
              let originalAddress = originalSenderAddress(),
              originalAddress.addressID != currentSenderAddress.addressID,
              originalAddress.status == .disabled else {
            return false
        }
        return true
    }

    func shouldShowErrorWhenOriginalAddressIsAnUnpaidPMAddress() -> Bool {
        guard let currentSenderAddress = currentSenderAddress(),
              let originalAddress = originalSenderAddress(),
              originalAddress.addressID != currentSenderAddress.addressID,
              originalAddress.send == .inactive,
              originalAddress.isPMAlias,
              !dependencies.userDefaults[.isPMMEWarningDisabled] else {
            return false
        }
        return true
    }
}

extension ComposeViewModel {
    struct Dependencies {
        let user: UserManager
        let coreDataContextProvider: CoreDataContextProviderProtocol
        let fetchAndVerifyContacts: FetchAndVerifyContactsUseCase
        let internetStatusProvider: InternetConnectionStatusProviderProtocol
        let keychain: Keychain
        let fetchAttachment: FetchAttachmentUseCase
        let contactProvider: ContactProviderProtocol
        let helperDependencies: ComposerMessageHelper.Dependencies
        let fetchMobileSignatureUseCase: FetchMobileSignatureUseCase
        let userDefaults: UserDefaults
        let notificationCenter: NotificationCenter
    }

    struct EncodableRecipient: Encodable {
        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case address = "Address"
            case group = "Group"
        }

        let name: String
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
