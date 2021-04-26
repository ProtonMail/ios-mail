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

protocol NewMessageBodyViewModelDelegate: class {
    func reloadWebView()
    func showReloadError()
    func updateBannerStatus()
}

class NewMessageBodyViewModel {
    private(set) var message: Message
    private let messageService: MessageDataService
    let userManager: UserManager
    private(set) var body: String?

    weak var delegate: NewMessageBodyViewModelDelegate?

    private(set) var shouldShowRemoteBanner = false

    var remoteContentPolicy: WebContents.RemoteContentPolicy.RawValue {
        didSet {
            reload(from: message)
            delegate?.reloadWebView()
        }
    }

    private(set) var contents: WebContents? {
        didSet {
            delegate?.reloadWebView()
        }
    }

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

    init(message: Message,
         messageService: MessageDataService,
         userManager: UserManager,
         shouldAutoLoadRemoteImages: Bool) {
        self.message = message
        self.messageService = messageService
        self.userManager = userManager

        remoteContentPolicy = shouldAutoLoadRemoteImages ?
            WebContents.RemoteContentPolicy.allowed.rawValue :
            WebContents.RemoteContentPolicy.disallowed.rawValue

        guard message.isDetailDownloaded else {
            return
        }

        reload(from: message)
    }

    func messageHasChanged(message: Message, isError: Bool = false) {
        self.message = message
        if isError {
            delegate?.showReloadError()
        } else {
            reload(from: message)
        }
    }

    private func reload(from message: Message) {
        guard let remoteContentMode = WebContents.RemoteContentPolicy(rawValue: self.remoteContentPolicy) else {
            return
        }
        if let decryptedBody = decryptBody(from: message) {
            body = decryptedBody

            checkBannerStatus(decryptedBody)

            showEmbedImage(message, body: decryptedBody) {
                self.contents = WebContents(body: self.body ?? "",
                                            remoteContentMode:
                                                remoteContentMode)
            }
        } else if !message.body.isEmpty {
            body = message.bodyToHtml()
            self.contents = WebContents(body: self.body ?? "",
                                        remoteContentMode:
                                            remoteContentMode)
        }
    }

    private func checkBannerStatus(_ bodyToCheck: String) {
        if remoteContentPolicy != WebContents.RemoteContentPolicy.allowed.rawValue {
            DispatchQueue.global().async { [weak self] in
                // this method is slow
                let shouldShowRemoteBanner = bodyToCheck.hasImage()
                DispatchQueue.main.async {
                    self?.shouldShowRemoteBanner = shouldShowRemoteBanner
                    self?.delegate?.updateBannerStatus()
                }
            }
        } else {
            self.shouldShowRemoteBanner = false
            delegate?.updateBannerStatus()
        }
    }

    private func decryptBody(from message: Message) -> String? {
        let expiration = message.expirationTime
        let expired = (expiration ?? .distantFuture).compare(Date()) == .orderedAscending
        guard !expired else {
            return LocalString._message_expired
        }

        if !message.isDetailDownloaded {
            return nil
        }

        do {
            return try messageService.decryptBodyIfNeeded(message: message) ?? LocalString._unable_to_decrypt_message
        } catch let error as NSError {
            PMLog.D("purifyEmailBody error : \(error)")
            return message.bodyToHtml()
        }
    }

    private func showEmbedImage(_ message: Message, body: String, completion: (() -> Void)?) {
        guard message.isDetailDownloaded,
            let allAttachments = message.attachments.allObjects as? [Attachment],
            case let atts = allAttachments.filter({ $0.inline() && $0.contentID()?.isEmpty == false }),
            !atts.isEmpty else {
            if self.body != body {
                self.body = body
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
                completion?()
            }
            if checkCount == strings.count {
                var updatedBody = body
                for (cid, base64) in strings {
                    if let token = updatedBody.range(of: cid) {
                        updatedBody.replaceSubrange(token, with: base64)
                    }
                }

                self.body = updatedBody
            } else {
                if self.body != body {
                    self.body = body
                }
            }
        }
    }
}
