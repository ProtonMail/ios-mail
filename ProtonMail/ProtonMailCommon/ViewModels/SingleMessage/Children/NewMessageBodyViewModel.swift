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

import ProtonCore_DataModel
import UIKit
import WebKit

protocol NewMessageBodyViewModelDelegate: AnyObject {
    func reloadWebView(forceRecreate: Bool)
    func showReloadError()
    func updateBannerStatus()
    func showDecryptionErrorBanner()
    func hideDecryptionErrorBanner()
    @available(iOS 12.0, *)
    func getUserInterfaceStyle() -> UIUserInterfaceStyle
    func sendDarkModeMetric(isApply: Bool)
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
    let darkModeCSS: String?

    init(originalBody: String, isNewsLetter: Bool, isPlainText: Bool) {
        self.originalBody = originalBody
        let level = CSSMagic.darkStyleSupportLevel(htmlString: originalBody,
                                                   isNewsLetter: isNewsLetter,
                                                   isPlainText: isPlainText)
        switch level {
        case .protonSupport:
            self.darkModeCSS = CSSMagic.generateCSSForDarkMode(htmlString: originalBody)
        case .notSupport:
            self.darkModeCSS = nil
        case .nativeSupport:
            self.darkModeCSS = ""
        }
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

private enum EmbeddedDownloadStatus {
    case none, downloading, finish
}

final class NewMessageBodyViewModel: LinkOpeningValidator {

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)?

    private(set) var message: MessageEntity
    private let messageDataProcessor: MessageDataProcessProtocol
    let userAddressUpdater: UserAddressUpdaterProtocol
    // [cid, base64String]
    private var embeddedBase64: [String: String] = [:]
    private var embeddedStatus = EmbeddedDownloadStatus.none
    var hasStrippedVersionObserver: ((Bool) -> Void)?
    private(set) var hasStrippedVersion: Bool = false
    private(set) var bodyParts: BodyParts? {
        didSet {
            DispatchQueue.main.async {
                self.hasStrippedVersion = self.bodyParts?.fullBody != self.bodyParts?.strippedBody
                self.hasStrippedVersionObserver?(self.hasStrippedVersion)
            }
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
    /// Queue to update embedded image data
    private lazy var replacementQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private(set) var contents: WebContents? {
        didSet {
            if !shouldHoldReloading {
                delegate?.reloadWebView(forceRecreate: false)
                self.sendMetricAPIIfNeeded()
            }
        }
    }
    private var hasAutoRetried = false

    var placeholderContent: String {
        var css: String
        switch currentMessageRenderStyle {
        case .lightOnly:
            css = WebContents.cssLightModeOnly
        case .dark:
            css = WebContents.css
        }

        let meta = "<meta name=\"viewport\" content=\"width=device-width\">"

        let htmlString = """
                            <html><head>\(meta)<style type='text/css'>
                            \(css)</style>
                            </head><body>\(LocalString._loading_)</body></html>
                         """
        return htmlString
    }

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

    let isDarkModeEnableClosure: () -> Bool

    /// This property is used to record the current render style of the message body in the webView.
    private(set) var currentMessageRenderStyle: MessageRenderStyle = .dark {
        didSet {
            self.contents?.changeRenderStyle(currentMessageRenderStyle)
        }
        willSet {
            if self.currentMessageRenderStyle == .dark && newValue == .lightOnly {
                self.delegate?.sendDarkModeMetric(isApply: false)
            }
            if self.currentMessageRenderStyle == .lightOnly && newValue == .dark {
                self.delegate?.sendDarkModeMetric(isApply: true)
            }
        }
    }
    var shouldDisplayRenderModeOptions: Bool {
        if message.isNewsLetter ||
           self.bodyParts?.darkModeCSS?.isEmpty ?? false { return false }
        return isDarkModeEnableClosure()
    }

    let linkConfirmation: LinkOpeningMode

    init(message: MessageEntity,
         messageDataProcessor: MessageDataProcessProtocol,
         userAddressUpdater: UserAddressUpdaterProtocol,
         shouldAutoLoadRemoteImages: Bool,
         shouldAutoLoadEmbeddedImages: Bool,
         internetStatusProvider: InternetConnectionStatusProvider,
         isDarkModeEnableClosure: @escaping () -> Bool,
         linkConfirmation: LinkOpeningMode
        ) {
        self.message = message
        self.messageDataProcessor = messageDataProcessor
        self.userAddressUpdater = userAddressUpdater
        self.internetStatusProvider = internetStatusProvider
        self.isDarkModeEnableClosure = isDarkModeEnableClosure
        if message.isPlainText {
            self.currentMessageRenderStyle = .dark
        } else {
            self.currentMessageRenderStyle = message.isNewsLetter ? .lightOnly : .dark
        }
        self.linkConfirmation = linkConfirmation

        remoteContentPolicy = shouldAutoLoadRemoteImages ?
            WebContents.RemoteContentPolicy.allowed.rawValue :
            WebContents.RemoteContentPolicy.disallowed.rawValue
        embeddedContentPolicy = shouldAutoLoadEmbeddedImages ? .allowed : .disallowed
    }

    func messageHasChanged(message: MessageEntity, isError: Bool = false) {
        if isError {
            delegate?.showReloadError()
        } else {
            reload(from: message)
        }
        self.message = message
    }

    func tryDecryptionAgain(handler: (() -> Void)?) {
        userAddressUpdater.updateUserAddresses {
            handler?()
        }
    }

    func reloadMessageWith(style: MessageRenderStyle) {
        self.currentMessageRenderStyle = style
        delegate?.reloadWebView(forceRecreate: false)
    }

    /// - Returns: Should reload webView or not
    @discardableResult
    private func reload(from message: MessageEntity) -> Bool {
        guard let remoteContentMode = WebContents.RemoteContentPolicy(rawValue: self.remoteContentPolicy) else {
            return true
        }
        if let decryptedBody = decryptBody(from: message) {
            isBodyDecryptable = true
            bodyParts = BodyParts(originalBody: decryptedBody,
                                  isNewsLetter: message.isNewsLetter,
                                  isPlainText: message.isPlainText)

            checkBannerStatus(decryptedBody)
            guard embeddedContentPolicy == .allowed else {
                let body = self.bodyParts?.body(for: displayMode) ?? ""
                self.contents = WebContents(body: body,
                                            remoteContentMode: remoteContentMode,
                                            renderStyle: self.currentMessageRenderStyle,
                                            supplementCSS: self.bodyParts?.darkModeCSS)
                return true
            }

            guard self.embeddedStatus == .finish else {
                let body = self.bodyParts?.body(for: displayMode) ?? ""
                self.contents = WebContents(body: body,
                                            remoteContentMode: remoteContentMode,
                                            renderStyle: self.currentMessageRenderStyle,
                                            supplementCSS: self.bodyParts?.darkModeCSS)
                DispatchQueue.global().async { self.downloadEmbedImage(message, body: decryptedBody) }
                return true
            }
            DispatchQueue.global().async { self.showEmbeddedImages(decryptedBody: decryptedBody) }
            return false
        } else if !message.body.isEmpty {
            var rawBody = message.body
            // If the string length is over 60k
            // The webview performance becomes bad
            // Cypher means nothing to human, 30k is enough
            let limit = 30_000
            if rawBody.count >= limit {
                let button = "<a href=\"\(String.fullDecryptionFailedViewLink)\">\(LocalString._show_full_message)</a>"
                let index = rawBody.index(rawBody.startIndex, offsetBy: limit)
                rawBody = String(rawBody[rawBody.startIndex..<index]) + button
                rawBody = "<div>\(rawBody)</div>"
            }
            // If the detail hasn't download, don't show encrypted body to user
            let originalBody = message.isDetailDownloaded ? message.htmlBody: .empty
            bodyParts = BodyParts(originalBody: originalBody,
                                  isNewsLetter: message.isNewsLetter,
                                  isPlainText: message.isPlainText)
            self.contents = WebContents(body: self.bodyParts?.body(for: displayMode) ?? "",
                                        remoteContentMode: remoteContentMode)
        }
        return true
    }

    private(set) var shouldShowRemoteBanner = false
    private(set) var shouldShowEmbeddedBanner = false

    private func checkBannerStatus(_ bodyToCheck: String) {
        let isHavingEmbeddedImages = self.containsEmbeddedImages(in: bodyToCheck, attachments: message.attachments)
        let helper = BannerHelper(embeddedContentPolicy: embeddedContentPolicy,
                                  remoteContentPolicy: remoteContentPolicy,
                                  isHavingEmbeddedImages: isHavingEmbeddedImages)
        helper.calculateBannerStatus(bodyToCheck: bodyToCheck) { [weak self] showRemoteBanner, showEmbeddedBanner in
            self?.shouldShowRemoteBanner = showRemoteBanner
            self?.shouldShowEmbeddedBanner = showEmbeddedBanner
            self?.delegate?.updateBannerStatus()
        }
    }

    private func containsEmbeddedImages(in decryptedBody: String?, attachments: [AttachmentEntity]) -> Bool {
        guard let body = decryptedBody else {
            let embedded = attachments
                .filter({ $0.isInline && $0.getContentID()?.isEmpty == false })
            return !embedded.isEmpty
        }
        let contentIDs = attachments.compactMap { $0.getContentID() }
        let embedded = contentIDs.filter { id in
            return body.preg_match("src=\"\(id)\"") ||
                body.preg_match("src=\"cid:\(id)\"") ||
                body.preg_match("data-embedded-img=\"\(id)\"") ||
                body.preg_match("data-src=\"cid:\(id)\"") ||
                body.preg_match("proton-src=\"cid:\(id)\"")
        }
        return !embedded.isEmpty
    }
}

extension NewMessageBodyViewModel {
    private func decryptBody(from message: MessageEntity) -> String? {
        let expiration = message.expirationTime
        let referenceDate = Date.getReferenceDate(processInfo: userCachedStatus)
        let expired = (expiration ?? .distantFuture).compare(referenceDate) == .orderedAscending
        guard !expired else {
            return LocalString._message_expired
        }

        if !message.isDetailDownloaded {
            return nil
        }

        do {
            let decryptedPair = try messageDataProcessor.messageDecrypter.decrypt(message: message)
            if decryptedPair.0 != nil {
                self.delegate?.hideDecryptionErrorBanner()
            }
            return decryptedPair.0
        } catch {
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

    private func downloadEmbedImage(_ message: MessageEntity, body: String) {
        guard self.embeddedStatus == .none,
              message.isDetailDownloaded,
              case let inlines = message.attachments.filter({ $0.isInline && $0.getContentID()?.isEmpty == false }),
              !inlines.isEmpty else {
                  if self.bodyParts?.originalBody != body {
                      self.bodyParts = BodyParts(originalBody: body,
                                                 isNewsLetter: message.isNewsLetter,
                                                 isPlainText: message.isPlainText)
                  }
                  return
              }
        self.embeddedStatus = .downloading
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "AttachmentQueue", qos: .userInitiated)
        let stringsQueue = DispatchQueue(label: "StringsQueue")

        for inline in inlines {
            group.enter()
            let work = DispatchWorkItem {
                self.messageDataProcessor.base64AttachmentData(inline) { based64String in
                    defer { group.leave() }
                    guard !based64String.isEmpty,
                          let contentID = inline.getContentID() else { return }
                    stringsQueue.sync {
                        let value = "src=\"data:\(inline.mimeType);base64,\(based64String)\""
                        self.embeddedBase64["src=\"cid:\(contentID)\""] = value
                    }
                }
            }
            queue.async(group: group, execute: work)
        }

        group.notify(queue: .global()) {
            self.embeddedStatus = .finish
            self.showEmbeddedImages(decryptedBody: body)
        }
    }

    private func showEmbeddedImages(decryptedBody: String) {
        self.replacementQueue.addOperation { [weak self] in
            guard let self = self,
                  self.embeddedStatus == .finish else { return }
            var updatedBody = decryptedBody
            let displayBody = self.bodyParts?.fullBody
            for (cid, base64) in self.embeddedBase64 {
                if let token = updatedBody.range(of: cid) {
                    updatedBody.replaceSubrange(token, with: base64)
                }
                if displayBody?.range(of: cid) == nil {
                    return
                }
            }
            self.bodyParts = BodyParts(originalBody: updatedBody,
                                       isNewsLetter: self.message.isNewsLetter,
                                       isPlainText: self.message.isPlainText)
            delay(0.2) {
                if let mode = WebContents.RemoteContentPolicy(rawValue: self.remoteContentPolicy) {
                    let body = self.bodyParts?.body(for: self.displayMode) ?? ""
                    self.contents = WebContents(body: body,
                                                remoteContentMode: mode,
                                                renderStyle: self.currentMessageRenderStyle,
                                                supplementCSS: self.bodyParts?.darkModeCSS)
                }
            }
        }
    }

    func sendMetricAPIIfNeeded(contents: WebContents? = nil) {
        var contents = contents
        if contents == nil {
            contents = self.contents
        }
        if #available(iOS 12.0, *) {
            guard let style = self.delegate?.getUserInterfaceStyle(),
                  style == .dark,
                  contents?.supplementCSS != nil,
                  contents?.renderStyle == .dark else { return }
            self.delegate?.sendDarkModeMetric(isApply: true)
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
