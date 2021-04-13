//
//  Standalone.swift
//  ProtonMail - Created on 14/03/2019.
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

/// ViewModel object representing one Message in a thread
class MessageViewModel: NSObject {
    
    internal enum Divisions: Int { // TODO: refactor with OptionSet
        // each division is perpresented by a single row in tableView
        case header = 0, attachments, remoteContent, body, expiration
    }
    
    internal let messageID: String
    @objc internal dynamic var body: String?
    @objc internal dynamic var header: HeaderData
    @objc internal dynamic var attachments: [AttachmentInfo]
    internal let expiration: Date?
    
    @objc internal dynamic var heightOfHeader: CGFloat = 0.0
    @objc internal dynamic var heightOfBody: CGFloat = 0.0
    @objc internal dynamic var heightOfAttachments: CGFloat = 0.0
    
    @objc internal dynamic var divisionsCount: Int
    private(set) var divisions: [Divisions] {
        didSet { self.divisionsCount = divisions.count }
    }
    
    @objc private(set) dynamic var remoteContentModeObservable: WebContents.RemoteContentPolicy.RawValue
    internal var remoteContentMode: WebContents.RemoteContentPolicy {
        get { return WebContents.RemoteContentPolicy(rawValue: self.remoteContentModeObservable)! }
        set {
            self.remoteContentModeObservable = newValue.rawValue
            if newValue == .allowed {
                self.divisions = self.divisions.filter { $0 != .remoteContent}
            } else if !self.divisions.contains(.remoteContent), let bodyIndex = self.divisions.firstIndex(of: .body) {
                self.divisions.insert(.remoteContent, at: bodyIndex)
            }
        }
    }
    
    
    let messageService : MessageDataService
    let user : UserManager
    
    convenience init(message: Message, msgService: MessageDataService, user: UserManager) {
        self.init(message: message, embeddingImages: true, messageService: msgService, user: user)
    }
    
    init(message: Message, embeddingImages: Bool, messageService: MessageDataService, user: UserManager) {
        
        self.messageService = messageService
        self.user = user
        // 0. expiration
        self.expiration = message.expirationTime
        let expired = (self.expiration ?? .distantFuture).compare(Date()) == .orderedAscending
        
        // 1. header
        self.header = HeaderData(message: message)
        
        // 2. body
        self.body = ""
        
        // 3. attachments
        var atts: [AttachmentInfo] = (message.attachments.allObjects as? [Attachment])?.map(AttachmentNormal.init) ?? [] // normal
        atts.append(contentsOf: message.tempAtts ?? []) // inline
        self.attachments = atts
        
        // 4. remote content policy
        self.remoteContentModeObservable = user.autoLoadRemoteImages ? WebContents.RemoteContentPolicy.allowed.rawValue : WebContents.RemoteContentPolicy.disallowed.rawValue
        
        
        // 5. divisions
        self.divisions = []
        self.divisions.append(.header)
        if self.expiration != nil {
            self.divisions.append(.expiration)
        }
        if !self.attachments.isEmpty, !expired  {
            self.divisions.append(.attachments)
        }
        self.divisions.append(.body)
        
        // others
        self.messageID = message.messageID
        self.divisionsCount = self.divisions.count
        
        super.init()
        self.decryptBody(message: message, expired: expired, shouldRetry: true)
        // there was a method embedding images here, revert and debug in case of problems
        
        if let expirationOffset = message.expirationTime?.timeIntervalSinceNow, expirationOffset > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(expirationOffset))) { [weak self, message] in
                self?.reload(from: message)
            }
        }
    }
    
    internal func reload(from message: Message) {
        let temp = MessageViewModel(message: message, embeddingImages: false, messageService: self.messageService, user: self.user)

        self.header = temp.header
        self.attachments = temp.attachments
        self.divisions = temp.divisions
        
        DispatchQueue.global().async { [weak self] in
            let hasImage = (temp.body ?? "").hasImage() // this method is slow
            DispatchQueue.main.async {
                guard let self = self else { return }
                if hasImage && !self.user.autoLoadRemoteImages { // we only care if there is remote content and loading is not allowed
                    self.remoteContentMode = .disallowed
                }
            }
        }
        
        if let body = temp.body {
            self.showEmbedImage(message, body: body)
        }
    }

    private func showEmbedImage(_ message: Message, body: String) {
        guard message.isDetailDownloaded,
            let allAttachments = message.attachments.allObjects as? [Attachment],
            case let atts = allAttachments.filter({ $0.inline() && $0.contentID()?.isEmpty == false }),
            !atts.isEmpty else
        {
            if self.body != body {
                self.body = body
            }
            return
        }
        
        let checkCount = atts.count
        let group: DispatchGroup = DispatchGroup()
        let queue: DispatchQueue = DispatchQueue(label: "AttachmentQueue", qos: .userInitiated)
        let stringsQueue: DispatchQueue = DispatchQueue(label: "StringsQueue")
        
        var strings: [String:String] = [:]
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
    
    private func getAddressKeys(message: Message, expired: Bool) {
        let req = GetAddressesRequest()
        self.user.apiService.exec(route: req) { (_, res: AddressesResponse) in
            guard res.error == nil else { return }
            self.user.userinfo.set(addresses: res.addresses)
            self.user.save()
            self.decryptBody(message: message,
                             expired: expired, shouldRetry: false)
        }
    }
    
    private func decryptBody(message: Message, expired: Bool, shouldRetry: Bool) {
        var body: String? = nil
        do {
            body = try messageService.decryptBodyIfNeeded(message: message) ?? LocalString._unable_to_decrypt_message
        } catch let ex as NSError {
            PMLog.D("purifyEmailBody error : \(ex)")
            body = message.bodyToHtml()
            if shouldRetry {
                self.getAddressKeys(message: message, expired: expired)
                return
            }
        }
        if expired {
            body = LocalString._message_expired
        }
        if !message.isDetailDownloaded {
            body = nil
        }
        self.body = body
    }
}
