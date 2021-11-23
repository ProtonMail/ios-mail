//
//  NewMessageBodyViewModel.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

protocol NewMessageBodyViewModelDelegate: AnyObject {
    func reloadWebView(forceRecreate: Bool)
    func showReloadError()
    func updateBannerStatus()
    func showDecryptionErrorBanner()
    func hideDecryptionErrorBanner()
}

enum MessageDisplayMode {
    case collapsed // Only latest message, without previous response
    case expanded // Full body

    mutating func toggle() {
        switch self {
        case .collapsed:
            self = .expanded
        case .expanded:
            self = .collapsed
        }
    }
}

struct BodyParts {
    let originalBody: String
    let strippedBody: String
    let fullBody: String

    init(originalBody: String) {
        self.originalBody = originalBody
        self.strippedBody = originalBody.body(strippedFromQuotes: true)
        self.fullBody = originalBody.body(strippedFromQuotes: false)
    }

    func body(for displayMode: MessageDisplayMode) -> String {
        switch displayMode {
        case .collapsed:
            return strippedBody
        case .expanded:
            return fullBody
        }
    }
}

class NewMessageBodyViewModel {

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)?

    private(set) var message: Message
    private let messageService: MessageDataService
    let userManager: UserManager
    var hasStrippedVersionObserver: ((Bool) -> Void)?
    private(set) var hasStrippedVersion: Bool = false
    private(set) var bodyParts: BodyParts? {
        didSet {
            hasStrippedVersion = bodyParts?.fullBody != bodyParts?.strippedBody
            hasStrippedVersionObserver?(hasStrippedVersion)
        }
    }
    private var shouldHoldReloading = false
    var displayMode: MessageDisplayMode = .collapsed {
        didSet {
            reload(from: message)
            // Calling reload will trigger contents to be set, so we prevent this to avoid having
            shouldHoldReloading = true
            delegate?.reloadWebView(forceRecreate: true)
            shouldHoldReloading = false
        }
    }

    let internetStatusProvider: InternetConnectionStatusProvider

    weak var delegate: NewMessageBodyViewModelDelegate?

    var remoteContentPolicy: WebContents.RemoteContentPolicy.RawValue {
        didSet {
            reload(from: message)
            if !shouldHoldReloading {
                delegate?.reloadWebView(forceRecreate: false)
            }
        }
    }

    var embeddedContentPolicy: WebContents.EmbeddedContentPolicy {
        didSet {
            if reload(from: message) {
                if !shouldHoldReloading {
                    delegate?.reloadWebView(forceRecreate: false)
                }
            }
        }
    }

    private(set) var contents: WebContents? {
        didSet {
            if !shouldHoldReloading {
                delegate?.reloadWebView(forceRecreate: false)
            }
        }
    }
    private var hasAutoRetried = false

    lazy var placeholderContent: String = {
        let meta = "<meta name=\"viewport\" content=\"width=device-width\">"

        let htmlString = """
                            <html><head>\(meta)<style type='text/css'>
                            \(WebContents.css)</style>
                            </head><body>\(LocalString._loading_)</body></html>
                         """
        return htmlString
    }()

    var webViewPreferences: WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
        preferences.javaScriptCanOpenWindowsAutomatically = false
        return preferences
    }

    var webViewConfig: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.phoneNumber, .link]
        return config
    }

    private(set) var isBodyDecryptable = false

    init(message: Message,
         messageService: MessageDataService,
         userManager: UserManager,
         shouldAutoLoadRemoteImages: Bool,
         shouldAutoLoadEmbeddedImages: Bool,
         internetStatusProvider: InternetConnectionStatusProvider) {
        self.message = message
        self.messageService = messageService
        self.userManager = userManager
        self.internetStatusProvider = internetStatusProvider

        remoteContentPolicy = shouldAutoLoadRemoteImages ?
            WebContents.RemoteContentPolicy.allowed.rawValue :
            WebContents.RemoteContentPolicy.disallowed.rawValue
        embeddedContentPolicy = shouldAutoLoadEmbeddedImages ? .allowed : .disallowed
    }

    func messageHasChanged(message: Message, isError: Bool = false) {
        if isError {
            delegate?.showReloadError()
        } else {
            reload(from: message)
        }
        self.message = message
    }

    func tryDecryptionAgain(handler: (() -> Void)?) {
        let req = GetAddressesRequest()
        self.userManager.apiService.exec(route: req) { [weak self] (_, res: AddressesResponse) in
            guard res.error == nil,
                  let self = self else { return }
            self.userManager.userinfo.set(addresses: res.addresses)
            self.userManager.save()
            self.reload(from: self.message)
            handler?()
        }
    }

    /// - Returns: Should reload webView or not
    @discardableResult
    private func reload(from message: Message) -> Bool {
        guard let remoteContentMode = WebContents.RemoteContentPolicy(rawValue: self.remoteContentPolicy) else {
            return true
        }
        if let decryptedBody = decryptBody(from: message) {
            isBodyDecryptable = true
            bodyParts = BodyParts(originalBody: decryptedBody)

            checkBannerStatus(decryptedBody)

            if embeddedContentPolicy == .allowed {
                showEmbedImage(message, body: decryptedBody) { [weak self] in
                    guard let self = self else { return }
                    self.contents = WebContents(
                        body: self.bodyParts?.body(for: self.displayMode) ?? "",
                        remoteContentMode: remoteContentMode
                    )
                }
                return false
            } else {
                self.contents = WebContents(body: self.bodyParts?.body(for: displayMode) ?? "",
                                            remoteContentMode:
                                                remoteContentMode)
            }
        } else if !message.body.isEmpty {
            // If the detail hasn't download, don't show encrypted body to user
            bodyParts = BodyParts(originalBody: message.isDetailDownloaded ? message.bodyToHtml(): .empty)
            self.contents = WebContents(body: self.bodyParts?.body(for: displayMode) ?? "",
                                        remoteContentMode:
                                            remoteContentMode)
        }
        return true
    }

    private(set) var shouldShowRemoteBanner = false
    private(set) var shouldShowEmbeddedBanner = false

    private func checkBannerStatus(_ bodyToCheck: String) {
        let isHavingEmbeddedImages = message.isHavingEmbeddedImages(decryptedBody: bodyToCheck)
        let helper = BannerHelper(embeddedContentPolicy: embeddedContentPolicy,
                                  remoteContentPolicy: remoteContentPolicy,
                                  isHavingEmbeddedImages: isHavingEmbeddedImages)
        helper.calculateBannerStatus(bodyToCheck: bodyToCheck) { [weak self] showRemoteBanner, showEmbeddedBanner in
            self?.shouldShowRemoteBanner = showRemoteBanner
            self?.shouldShowEmbeddedBanner = showEmbeddedBanner
            self?.delegate?.updateBannerStatus()
        }
    }

    private func decryptBody(from message: Message) -> String? {
        let expiration = message.expirationTime
        let expired = (expiration ?? .distantFuture).compare(Date.unixDate) == .orderedAscending
        guard !expired else {
            return LocalString._message_expired
        }

        if !message.isDetailDownloaded {
            return nil
        }

        do {
            let decryptedMessage = try messageService.decryptBodyIfNeeded(message: message)
            if decryptedMessage != nil {
                self.delegate?.hideDecryptionErrorBanner()
            }
            return decryptedMessage
        } catch let error as NSError {
            PMLog.D("purifyEmailBody error : \(error)")
            self.delegate?.showDecryptionErrorBanner()
            if !self.hasAutoRetried {
                // If failed, auto retry one time
                // Maybe the user just imported a key and event api not sync yet
                self.hasAutoRetried = true
                self.tryDecryptionAgain(handler: nil)
            }
            return nil
        }
    }

    private func showEmbedImage(_ message: Message, body: String, completion: (() -> Void)?) {
        guard message.isDetailDownloaded,
            let allAttachments = message.attachments.allObjects as? [Attachment],
            case let atts = allAttachments.filter({ $0.inline() && $0.contentID()?.isEmpty == false }),
            !atts.isEmpty else {
            if self.bodyParts?.originalBody != body {
                self.bodyParts = BodyParts(originalBody: body)
            }
            completion?()
            return
        }

        let checkCount = atts.count
        let group: DispatchGroup = DispatchGroup()
        let queue: DispatchQueue = DispatchQueue(label: "AttachmentQueue", qos: .userInitiated)
        let stringsQueue: DispatchQueue = DispatchQueue(label: "StringsQueue")

        var strings: [String: String] = [:]
        for att in atts {
            group.enter()
            let work = DispatchWorkItem {
                self.messageService.base64AttachmentData(att: att) { based64String in
                    if !based64String.isEmpty, let contentID = att.contentID() {
                        stringsQueue.sync {
                            strings["src=\"cid:\(contentID)\""] = "src=\"data:\(att.mimeType);base64,\(based64String)\""
                        }
                    }
                    group.leave()
                }
            }
            queue.async(group: group, execute: work)
        }

        group.notify(queue: .main) {
            defer {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    completion?()
                }
            }
            if checkCount == strings.count {
                var updatedBody = body
                for (cid, base64) in strings {
                    if let token = updatedBody.range(of: cid) {
                        updatedBody.replaceSubrange(token, with: base64)
                    }
                }

                self.bodyParts = BodyParts(originalBody: updatedBody)
            } else {
                if self.bodyParts?.originalBody != body {
                    self.bodyParts = BodyParts(originalBody: body)
                }
            }
        }
    }
}

struct BannerHelper {
    let embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    let remoteContentPolicy: WebContents.RemoteContentPolicy.RawValue
    let isHavingEmbeddedImages: Bool

    func calculateBannerStatus(bodyToCheck: String, result: @escaping (Bool, Bool) -> Void) {
        calculateRemoteBannerStatus(bodyToCheck: bodyToCheck) { shouldShowRemoteBanner in
            let shouldShowEmbeddedBanner = self.shouldShowEmbeddedBanner()
            result(shouldShowRemoteBanner, shouldShowEmbeddedBanner)
        }
    }

    func calculateRemoteBannerStatus(bodyToCheck: String, result: @escaping ((Bool) -> Void)) {
        if remoteContentPolicy != WebContents.RemoteContentPolicy.allowed.rawValue {
            DispatchQueue.global().async {
                // this method is slow
                let shouldShowRemoteBanner = bodyToCheck.hasImage()
                DispatchQueue.main.async {
                    result(shouldShowRemoteBanner)
                }
            }
        } else {
            result(false)
        }
    }

    func shouldShowEmbeddedBanner() -> Bool {
        return embeddedContentPolicy != .allowed && isHavingEmbeddedImages
    }
}

extension Message {
    func isHavingEmbeddedImages(decryptedBody: String? = nil) -> Bool {
        guard let attachments = self.attachments.allObjects as? [Attachment] else {
            return false
        }
        guard let body = decryptedBody else {
            let atts = attachments
                .filter({ $0.inline() && $0.contentID()?.isEmpty == false })
            return !atts.isEmpty
        }
        let cids = attachments.compactMap { $0.contentID() }
        let inlines = cids.filter { cid in
            return body.preg_match("src=\"\(cid)\"") ||
                body.preg_match("src=\"cid:\(cid)\"") ||
                body.preg_match("data-embedded-img=\"\(cid)\"") ||
                body.preg_match("data-src=\"cid:\(cid)\"") ||
                body.preg_match("proton-src=\"cid:\(cid)\"")
        }
        return !inlines.isEmpty
    }

    func getCIDOfInlineAttachment(decryptedBody: String?) -> [String]? {
        guard let attachments = self.attachments.allObjects as? [Attachment],
              let body = decryptedBody else {
            return nil
        }
        let cids = attachments.compactMap { $0.contentID() }
        let inlines = cids.filter { cid in
            return body.preg_match("src=\"\(cid)\"") ||
                body.preg_match("src=\"cid:\(cid)\"") ||
                body.preg_match("data-embedded-img=\"\(cid)\"") ||
                body.preg_match("data-src=\"cid:\(cid)\"") ||
                body.preg_match("proton-src=\"cid:\(cid)\"")
        }
        return inlines
    }
}
