// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import PromiseKit
import ProtonCoreDataModel
import ProtonCoreServices
import ProtonCoreUIFoundations

protocol MessageInfoProviderDelegate: AnyObject {
    func providerHasChanged()
    func hideDecryptionErrorBanner()
    func showDecryptionErrorBanner()
    func updateBannerStatus()
    func update(content: WebContents?)
    func update(hasStrippedVersion: Bool)
    func update(renderStyle: MessageRenderStyle)
    func sendDarkModeMetric(isApply: Bool)
    func updateAttachments()
    func trackerProtectionSummaryChanged()
}

private enum EmbeddedDownloadStatus {
    case none, downloading, finish
}

// swiftlint:disable:next type_body_length
final class MessageInfoProvider {
    typealias Dependencies = MessageSenderPGPChecker.Dependencies
    & HasContactPickerModelHelper
    & HasFetchSenderImage
    & HasImageProxy
    & HasUserDefaults

    private(set) var message: MessageEntity {
        willSet {
            let bodyHasChanged = message.body != newValue.body
            if bodyHasChanged || bodyParts == nil {
                bodyParts = nil
                hasAutoRetriedDecrypt = false
                trackerProtectionSummary = nil
            }
        }
        didSet {
            let bodyHasChanged = message.body != oldValue.body
            let isDetailDownloadedHasChanged = message.isDetailDownloaded != oldValue.isDetailDownloaded
            if bodyHasChanged || bodyParts == nil || isDetailDownloadedHasChanged {
                pgpChecker = MessageSenderPGPChecker(message: message, dependencies: dependencies)
                prepareDisplayBody()
                checkSenderPGP()
            }
            delegate?.updateAttachments()
        }
    }

    private(set) var trackerProtectionSummary: TrackerProtectionSummary? {
        didSet {
            guard trackerProtectionSummary != oldValue else {
                return
            }

            delegate?.trackerProtectionSummaryChanged()
        }
    }

    private let contactService: ContactDataService
    private let contactGroupService: ContactGroupsDataService
    private let messageDecrypter: MessageDecrypter
    private let userAddressUpdater: UserAddressUpdaterProtocol
    private let systemUpTime: SystemUpTimeProtocol
    private let user: UserManager
    private let labelID: LabelID
    private weak var delegate: MessageInfoProviderDelegate?
    private var pgpChecker: MessageSenderPGPChecker?
    private let dependencies: Dependencies
    private var highlightedKeywords: [String]

    private var shouldApplyImageProxy: Bool {
        let messageNotSentByUs = !message.isSent
        let remoteContentAllowed = remoteContentPolicy == .allowedThroughProxy
        return messageNotSentByUs && remoteContentAllowed && imageProxyEnabled
    }
    var imageProxyEnabled: Bool {
        user.userInfo.imageProxy.contains(.imageProxy) && !message.isSent
    }
    var remoteContentPolicy: WebContents.RemoteContentPolicy {
        didSet {
            if message.isSent && remoteContentPolicy == .allowedThroughProxy {
                remoteContentPolicy = .allowedWithoutProxy
            }
            if !imageProxyEnabled && remoteContentPolicy == .allowedThroughProxy {
                remoteContentPolicy = .allowedWithoutProxy
            }
            if remoteContentPolicy == .allowedWithoutProxy {
                shouldShowImageProxyFailedBanner = false
            }
            prepareDisplayBody()
        }
    }

    private let dateFormatter: PMDateFormatter

    init(
        message: MessageEntity,
        messageDecrypter: MessageDecrypter? = nil,
        systemUpTime: SystemUpTimeProtocol,
        labelID: LabelID,
        dependencies: Dependencies,
        highlightedKeywords: [String],
        dateFormatter: PMDateFormatter = .shared
    ) {
        self.message = message
        pgpChecker = MessageSenderPGPChecker(message: message, dependencies: dependencies)
        self.user = dependencies.user
        self.contactService = user.contactService
        self.contactGroupService = user.contactGroupService
        self.messageDecrypter = messageDecrypter ?? user.messageService.messageDecrypter

        // If the message is sent by us, we do not use the image proxy to load the content.
        let imageProxyEnabled = user.userInfo.imageProxy.contains(.imageProxy) && !message.isSent
        let allowedPolicy: WebContents.RemoteContentPolicy = !imageProxyEnabled ? .allowedWithoutProxy : .allowedThroughProxy
        self.remoteContentPolicy = user.userInfo.isAutoLoadRemoteContentEnabled ? allowedPolicy : .disallowed

        self.embeddedContentPolicy = user.userInfo.isAutoLoadEmbeddedImagesEnabled ? .allowed : .disallowed
        self.userAddressUpdater = user
        self.systemUpTime = systemUpTime
        self.labelID = labelID
        self.dependencies = dependencies
        self.highlightedKeywords = highlightedKeywords
        self.dateFormatter = dateFormatter

        if message.isPlainText {
            self.currentMessageRenderStyle = .dark
        } else {
            self.currentMessageRenderStyle = .dark
        }
    }

    func initialize() {
        dependencies.imageProxy.set(delegate: self)
        self.prepareDisplayBody()
        self.checkSenderPGP()
    }

    lazy var senderName: NSAttributedString = {
        let sender: Sender

        do {
            sender = try message.parseSender()
        } catch {
            assertionFailure("\(error)")
            return .init(string: "")
        }

        guard let contactName = contactService.getName(of: sender.address) else {
            let name = sender.name.isEmpty ? sender.address : sender.name
            return name.keywordHighlighting.asAttributedString(keywords: highlightedKeywords)
        }
        return contactName.keywordHighlighting.asAttributedString(keywords: highlightedKeywords)
    }()

    private(set) var checkedSenderContact: CheckedSenderContact? {
        didSet {
            delegate?.providerHasChanged()
        }
    }

    var initials: String { senderName.string.initials() }

    var senderEmail: NSAttributedString {
        do {
            let sender = try message.parseSender()
            return sender.address.keywordHighlighting.asAttributedString(keywords: highlightedKeywords)
        } catch {
            assertionFailure("\(error)")
            return .init(string: "")
        }
    }

    var time: String {
        if message.contains(location: .scheduled), let date = message.time {
            return dateFormatter.stringForScheduledMsg(from: date)
        } else if let date = message.time {
            return dateFormatter.string(from: date, weekStart: user.userInfo.weekStartValue)
        } else {
            return .empty
        }
    }

    lazy var date: String? = {
        guard let date = message.time else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        dateFormatter.dateStyle = .long
        dateFormatter.locale = LocaleEnvironment.locale()
        return dateFormatter.string(from: date)
    }()

    func originImage(isExpanded: Bool) -> UIImage? {
        if isExpanded && message.isSent {
            // In expanded header, we prioritize to show the sent location.
            return LabelLocation.sent.icon
        }

        let id = message.messageLocation?.labelID ?? labelID
        if let image = message.getLocationImage(in: id) {
            return image
        }
        return message.isCustomFolder ? IconProvider.folder : nil
    }

    func originFolderTitle(isExpanded: Bool) -> String? {
        if isExpanded && message.isSent {
            // In expanded header, we prioritize to show the sent location.
            return LabelLocation.sent.localizedTitle
        }

        if let locationName = message.messageLocation?.localizedTitle {
            return locationName
        }
        return message.customFolder?.name
    }

    var size: String { message.size.toByteCount }

    private lazy var groupContacts: [ContactGroupVO] = { [unowned self] in
        contactGroupService.getAllContactGroupVOs()
    }()

    private var userContacts: [ContactVO] {
        contactService.allContactVOs()
    }

    var simpleRecipient: NSAttributedString? {
        let lists = dependencies.contactPickerModelHelper.contacts(from: message.rawCCList)
        + dependencies.contactPickerModelHelper.contacts(from: message.rawBCCList)
        + dependencies.contactPickerModelHelper.contacts(from: message.rawTOList)
        let groups = lists.compactMap { $0 as? ContactGroupVO }
        let groupNames = groups.names(allGroupContacts: groupContacts)
        let receiver = recipientNames(from: lists)
        let result = groupNames + receiver
        let name = result.asCommaSeparatedList(trailingSpace: true)
        let recipients = name.isEmpty ? LocalString._undisclosed_recipients : name
        return recipients.keywordHighlighting.asAttributedString(keywords: highlightedKeywords)
    }

    lazy var toData: ExpandedHeaderRecipientsRowViewModel? = {
        let toList = dependencies.contactPickerModelHelper.contacts(from: message.rawTOList)
        var list: [ContactVO] = toList.compactMap({ $0 as? ContactVO })
        toList
            .compactMap({ $0 as? ContactGroupVO })
            .forEach { group in
                group.getSelectedEmailData()
                    .compactMap { ContactVO(name: $0.name, email: $0.email) }
                    .forEach { list.append($0) }
            }
        return createRecipientRowViewModel(
            from: list,
            title: "\(LocalString._general_to_label):"
        )
    }()

    lazy var ccData: ExpandedHeaderRecipientsRowViewModel? = {
        let list = ContactPickerModelHelper.nonGroupContacts(from: message.rawCCList)
        return createRecipientRowViewModel(from: list, title: "\(LocalString._general_cc_label):")
    }()

    lazy var bccData: ExpandedHeaderRecipientsRowViewModel? = {
        let list = ContactPickerModelHelper.nonGroupContacts(from: message.rawBCCList)
        return createRecipientRowViewModel(from: list, title: LocalString._general_bcc_label)
    }()

    // [cid, base64String]
    private var inlineContentIDMap: [String: String] = [:]
    private var embeddedStatus = EmbeddedDownloadStatus.none
    private(set) var hasStrippedVersion: Bool = false {
        didSet { delegate?.update(hasStrippedVersion: hasStrippedVersion) }
    }

    private(set) var shouldShowRemoteBanner = false
    private(set) var shouldShowEmbeddedBanner = false

    var shouldShowImageProxyFailedBanner: Bool = false

    private var hasAutoRetriedDecrypt = false
    private(set) var bodyParts: BodyParts? {
        didSet {
            hasStrippedVersion = bodyParts?.bodyHasHistory ?? false
            inlineAttachments = inlineImages(in: bodyParts?.originalBody, attachments: message.attachments)
        }
    }
    private(set) var contents: WebContents? {
        didSet { delegate?.update(content: self.contents) }
    }
    private(set) var isBodyDecryptable: Bool = false

    var embeddedContentPolicy: WebContents.EmbeddedContentPolicy {
        didSet {
            guard embeddedContentPolicy != oldValue else { return }
            prepareDisplayBody()
        }
    }

    var displayMode: MessageDisplayMode = .collapsed {
        didSet {
            guard displayMode != oldValue else { return }
            prepareDisplayBody()
        }
    }

    /// This property is used to record the current render style of the message body in the webView.
    var currentMessageRenderStyle: MessageRenderStyle {
        didSet {
            contents?.renderStyle = currentMessageRenderStyle
            delegate?.update(renderStyle: currentMessageRenderStyle)
        }
        willSet {
            if currentMessageRenderStyle == .dark && newValue == .lightOnly {
                delegate?.sendDarkModeMetric(isApply: false)
            }
            if currentMessageRenderStyle == .lightOnly && newValue == .dark {
                delegate?.sendDarkModeMetric(isApply: true)
            }
        }
    }

    var shouldDisplayRenderModeOptions: Bool {
            if dependencies.userDefaults[.darkModeStatus] == .forceOff {
                return false
            }
            let keywords = ["color-scheme", "supported-color-schemes", #"color-scheme:\s?\S{0,}\s?dark"#]
            if keywords.contains(where: { bodyParts?.originalBody.preg_match($0) ?? false }) {
                return false
            } else {
                return true
            }
    }

    private let dispatchQueue = DispatchQueue(
        label: "me.proton.mail.MessageInfoProvider",
        qos: .userInteractive
    )

    private(set) var inlineAttachments: [AttachmentEntity]? {
        didSet {
            guard inlineAttachments != oldValue else { return }
            delegate?.updateAttachments()
        }
    }
    var nonInlineAttachments: [AttachmentEntity] {
        let inlineIDs = inlineAttachments?.map { $0.id } ?? []
        return message.attachments.filter { !inlineIDs.contains($0.id) }
    }

    private(set) var mimeAttachments: [MimeAttachment] = [] {
        didSet {
            guard mimeAttachments != oldValue else { return }
            delegate?.updateAttachments()
        }
    }

    var scheduledSendingTime: (String, String)? {
        guard let time = message.time, message.contains(location: .scheduled) else {
            return nil
        }
        return PMDateFormatter.shared.titleForScheduledBanner(from: time)
    }
}

// MARK: Public functions
extension MessageInfoProvider {
    func update(message: MessageEntity) {
        dispatchQueue.async {
            self.message = message
        }
    }

    func tryDecryptionAgain(handler: (() -> Void)?) {
        userAddressUpdater.updateUserAddresses { [weak self] in
            self?.bodyParts = nil
            self?.prepareDisplayBody()
            self?.dispatchQueue.async {
                handler?()
            }
        }
    }

    func set(delegate: MessageInfoProviderDelegate) {
        self.delegate = delegate
    }

    func set(policy: WebContents.RemoteContentPolicy) {
        guard policy != remoteContentPolicy else {
            return
        }
        remoteContentPolicy = policy
    }

    func reloadImagesWithoutProtection() {
        remoteContentPolicy = .allowedWithoutProxy
	}

    func fetchSenderImageIfNeeded(
        isDarkMode: Bool,
        scale: CGFloat,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let senderImageRequestInfo = message.getSenderImageRequestInfo(isDarkMode: isDarkMode) else {
            completion(nil)
            return
        }

        dependencies.fetchSenderImage
            .callbackOn(.main)
            .execute(
                params: .init(
                    senderImageRequestInfo: senderImageRequestInfo,
                    scale: scale,
                    userID: user.userID
                )) { result in
                    switch result {
                    case .success(let image):
                        completion(image)
                    case .failure:
                        completion(nil)
                    }
            }
    }
}

// MARK: Contact related
extension MessageInfoProvider {
    private func recipientNames(from recipients: [ContactPickerModelProtocol]) -> [String] {
        recipients
            .compactMap { item -> String? in
                guard let contact = item as? ContactVO else {
                    return nil
                }
                guard let name = contactService.getName(of: contact.email) else {
                    let name = contact.displayName ?? ""
                    return name.isEmpty ? contact.displayEmail : name
                }
                return name
            }
    }

    private func checkSenderPGP() {
        guard checkedSenderContact?.encryptionIconStatus == nil, message.isDetailDownloaded else { return }
        pgpChecker?.check { [weak self] contact in
            self?.checkedSenderContact = contact
        }
    }

    private func createRecipientRowViewModel(
        from contacts: [ContactVO],
        title: String
    ) -> ExpandedHeaderRecipientsRowViewModel? {
        guard !contacts.isEmpty else { return nil }
        let recipients = contacts.map { recipient -> ExpandedHeaderRecipientRowViewModel in
            let email = recipient.email.isEmpty ? "" : "\(recipient.email)"
            let emailToDisplay = email.isEmpty ? "" : "\(email)"
            let nameFromContact = recipient.getName(in: userContacts) ?? .empty
            let name = nameFromContact.isEmpty ? email : nameFromContact
            let contact = ContactVO(name: name, email: recipient.email)
            return ExpandedHeaderRecipientRowViewModel(
                name: name.keywordHighlighting.asAttributedString(keywords: highlightedKeywords),
                address: emailToDisplay.keywordHighlighting.asAttributedString(keywords: highlightedKeywords),
                contact: contact
            )
        }
        return ExpandedHeaderRecipientsRowViewModel(
            title: title,
            recipients: recipients
        )
    }
}

// MARK: Body related
extension MessageInfoProvider {
    private func prepareDisplayBody() {
        dispatchQueue.async {
            self.checkAndDecryptBody()
            guard let decryptedBody = self.bodyParts?.originalBody else {
                self.prepareDecryptFailedBody()
                return
            }

            self.checkBannerStatus(decryptedBody)

            guard self.embeddedContentPolicy == .allowed,
                  !(self.inlineAttachments ?? []).isEmpty else {
                self.updateWebContents()
                return
            }

            guard self.embeddedStatus == .finish else {
                // If embedded images haven't prepared
                // Display content first
                // Reload view after preparing
                // If embedded images are cached, doesn't need to show blank content
                if self.needsToDownloadEmbeddedImage() {
                    self.updateWebContents()
                }
                self.downloadEmbedImage(self.message)
                return
            }

            self.showEmbeddedImages()
        }
    }

    private func prepareDecryptFailedBody() {
        guard !message.body.isEmpty else { return }
        var rawBody = message.body
        // If the string length is over 60k
        // The web view performance becomes bad
        // Cypher means nothing to human, 30k is enough
        let limit = 30_000
        if rawBody.count >= limit {
            let button = "<a href=\"\(String.fullDecryptionFailedViewLink)\">\(LocalString._show_full_message)</a>"
            let index = rawBody.index(rawBody.startIndex, offsetBy: limit)
            rawBody = String(rawBody[rawBody.startIndex..<index]) + button
            rawBody = "<div>\(rawBody)</div>"
        }
        // If the detail hasn't download, don't show encrypted body to user
        if message.isDetailDownloaded {
            updateBodyParts(with: rawBody)
            updateWebContents()
        }
    }

    private func checkAndDecryptBody() {
        let expiration = message.expirationTime
        let referenceDate = Date.getReferenceDate(processInfo: systemUpTime)
        let expired = (expiration ?? .distantFuture).compare(referenceDate) == .orderedAscending
        guard !expired else {
            updateBodyParts(with: LocalString._message_expired)
            return
        }

        guard message.isDetailDownloaded || !message.body.isEmpty else {
            return
        }

        let decryptionIsNeeded = bodyParts == nil
        guard decryptionIsNeeded else { return }
        if let result = decryptBody() {
            updateBodyParts(with: result.body)
            mimeAttachments = result.attachments ?? []
        } else {
            bodyParts = nil
            mimeAttachments = []
        }
    }

    private func decryptBody() -> MessageDecrypter.DecryptionOutput? {
        do {
            let decryptionOutput = try messageDecrypter.decrypt(message: message)
            isBodyDecryptable = true
            delegate?.hideDecryptionErrorBanner()
            return decryptionOutput
        } catch {
            delegate?.showDecryptionErrorBanner()
            if !hasAutoRetriedDecrypt {
                // If failed, auto retry one time
                // Maybe the user just imported a key and event api not sync yet
                hasAutoRetriedDecrypt = true
                tryDecryptionAgain(handler: nil)
            }
            return nil
        }
    }

    private func updateBodyParts(with newBody: String) {
        guard newBody != bodyParts?.originalBody,
              let sender = try? message.parseSender() else {
            return
        }
        bodyParts = BodyParts(originalBody: newBody, sender: sender.address)
    }

    private func updateWebContents() {
        let attachments = (inlineAttachments ?? []) + nonInlineAttachments
        let webImages = WebImageContents(
            embeddedImages: attachments
        )

        let body = bodyParts?.originalBody ?? .empty

        let contentLoadingType: WebContents.LoadingType
        // The sent message will not use the proxy. The remote content should be loaded directly through the webview.
        if message.isSent && remoteContentPolicy == .allowedThroughProxy {
            remoteContentPolicy = .allowedWithoutProxy
            contentLoadingType = .skipProxy
            // The `allowedAll` policy will by pass the proxy and load the content through the webview.
        } else if remoteContentPolicy == .allowedWithoutProxy {
            contentLoadingType = .skipProxy
        } else if shouldApplyImageProxy {
            contentLoadingType = .proxy
        } else if imageProxyEnabled {
            contentLoadingType = .skipProxyButAskForTrackerInfo
        } else {
            contentLoadingType = .skipProxy
        }

        let css = bodyParts?.darkModeCSS(darkModeStatus: dependencies.userDefaults[.darkModeStatus])
        contents = WebContents(
            body: body.keywordHighlighting.usingCSS(keywords: highlightedKeywords),
            remoteContentMode: remoteContentPolicy,
            messageDisplayMode: displayMode,
            contentLoadingType: contentLoadingType,
            renderStyle: currentMessageRenderStyle,
            supplementCSS: css,
            webImages: webImages
        )
    }
}

// MARK: Attachments
extension MessageInfoProvider {
    // Some sender / email provider will set disposition of inline as attachment
    // To make sure get correct inlines, needs to check with decrypted body
    private func inlineImages(in decryptedBody: String?, attachments: [AttachmentEntity]) -> [AttachmentEntity]? {
        guard let body = decryptedBody else { return nil }
        if let inlines = inlineAttachments { return inlines }
        let result = attachments.filter { attachment in
            guard let contentID = attachment.getContentID() else { return false }
            if body.preg_match("((src)|(data-embedded-img)|(data-src)|(proton-src))=['|\"](cid:)?\(contentID)['|\"]") {
                return true
            }
            return false
        }
        return result
    }

    private func downloadEmbedImage(_ message: MessageEntity) {
        guard self.embeddedStatus == .none,
              message.isDetailDownloaded,
              let inlines = inlineAttachments,
              !inlines.isEmpty else {
            return
        }
        self.embeddedStatus = .downloading
        let group = DispatchGroup()
        let stringsQueue = DispatchQueue(label: "StringsQueue")
        let userKeys = user.toUserKeys()

        for inline in inlines {
            guard let contentID = inline.getContentID() else { return }
            group.enter()
            dependencies.fetchAttachment.execute(
                params: .init(
                    attachmentID: inline.id,
                    attachmentKeyPacket: inline.keyPacket,
                    userKeys: userKeys
                )
            ) { [weak self] result in
                guard let base64Attachment = try? result.get().data.base64EncodedString(),
                      !base64Attachment.isEmpty else {
                    group.leave()
                    return
                }
                stringsQueue.sync {
                    let scheme = HTTPRequestSecureLoader.imageCacheScheme
                    let value = "src=\"\(scheme)://\(inline.id)\""
                    self?.inlineContentIDMap["\(contentID)"] = value
                }
                group.leave()
            }
        }

        group.notify(queue: .global()) {
            self.embeddedStatus = .finish
            self.showEmbeddedImages()
        }
    }

    private func showEmbeddedImages() {
        dispatchQueue.async { [weak self] in
            guard
                let self = self,
                self.embeddedStatus == .finish,
                let currentlyDisplayedBodyParts = self.bodyParts
            else {
                return
            }

            var updatedBody = currentlyDisplayedBodyParts.originalBody
            for (cid, cidWithScheme) in self.inlineContentIDMap {
                // The symbol in the raw html could be `'` or `"`
                // Needs to use correct one or the replacement will fail
                guard let symbol = updatedBody.preg_match(resultInGroup: 1, "src=(['|\"])cid:\(cid)") else { continue }
                updatedBody = updatedBody
                    .replacingOccurrences(of: "src=\(symbol)cid:\(cid)\(symbol)", with: cidWithScheme)
            }
            self.updateBodyParts(with: updatedBody)
            self.updateWebContents()
        }
    }

    private func needsToDownloadEmbeddedImage() -> Bool {
        guard let inlines = inlineAttachments,
              !inlines.isEmpty else {
            return false
        }
        var needsDownload = false
        for inline in inlines {
            let path = FileManager.default.attachmentDirectory.appendingPathComponent(inline.id.rawValue)
            if !FileManager.default.fileExists(atPath: path.relativePath) {
                needsDownload = true
                break
            }
        }
        return needsDownload
    }

    private func checkBannerStatus(_ bodyToCheck: String) {
        let isHavingEmbeddedImages = !(inlineAttachments ?? []).isEmpty

        let helper = BannerHelper(embeddedContentPolicy: embeddedContentPolicy,
                                  remoteContentPolicy: remoteContentPolicy,
                                  isHavingEmbeddedImages: isHavingEmbeddedImages)
        helper.calculateBannerStatus(bodyToCheck: bodyToCheck) { [weak self] showRemoteBanner, showEmbeddedBanner in
            self?.shouldShowRemoteBanner = showRemoteBanner
            self?.shouldShowEmbeddedBanner = showEmbeddedBanner
            self?.delegate?.updateBannerStatus()
        }
    }
}

extension MessageInfoProvider: ImageProxyDelegate {
    func imageProxy(_ imageProxy: ImageProxy, output: ImageProxyOutput) {
        shouldShowImageProxyFailedBanner = output.hasEncounteredErrors
        trackerProtectionSummary = output.summary
        delegate?.updateBannerStatus()
    }
}
