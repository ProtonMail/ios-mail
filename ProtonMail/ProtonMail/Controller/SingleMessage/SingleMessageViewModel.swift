//
//  SingleMessageViewModel.swift
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

import PMUIFoundations

class SingleMessageViewModel {

    var message: Message {
        didSet {
            propagateMessageData()
        }
    }
    let shouldAutoLoadRemoteImage: Bool

    let messageBodyViewModel: NewMessageBodyViewModel
    let nonExapndedHeaderViewModel: NonExpandedHeaderViewModel
    let attachmentViewModel: AttachmentViewModel
    let bannerViewModel: BannerViewModel
    private(set) lazy var userActivity: NSUserActivity = .messageDetailsActivity(messageId: message.messageID)

    private let messageService: MessageDataService
    let user: UserManager
    private let labelId: String
    private let messageObserver: MessageObserver
    let linkOpener: LinkOpener

    var refreshView: (() -> Void)?
    var updateErrorBanner: ((NSError?) -> Void)?

    init(labelId: String, message: Message, user: UserManager, linkOpenerCache: LinkOpenerCacheProtocol) {
        self.labelId = labelId
        self.message = message
        self.messageService = user.messageService
        self.user = user
        self.linkOpener = linkOpenerCache.browser
        self.shouldAutoLoadRemoteImage = user.autoLoadRemoteImages
        self.messageBodyViewModel = NewMessageBodyViewModel(message: message,
                                                            messageService: user.messageService,
                                                            userManager: user,
                                                            shouldAutoLoadRemoteImages: user.autoLoadRemoteImages)
        self.nonExapndedHeaderViewModel = NonExpandedHeaderViewModel(
            labelId: labelId,
            message: message,
            user: user
        )
        self.bannerViewModel = BannerViewModel(shouldAutoLoadRemoteContent: user.autoLoadRemoteImages,
                                               expirationTime: message.expirationTime)
        let attachments: [AttachmentInfo] = message.attachments.compactMap { $0 as? Attachment }
            .map(AttachmentNormal.init) + (message.tempAtts ?? [])

        self.attachmentViewModel = AttachmentViewModel(attachments: attachments)
        self.messageObserver = MessageObserver(messageId: message.messageID, messageService: messageService)
    }

    var messageTitle: NSAttributedString {
        message.title.apply(style: .titleAttributes)
    }

    func viewDidLoad() {
        messageObserver.observe { [weak self] in
            self?.message = $0
        }
        downloadDetails()
    }

    func propagateMessageData() {
        refreshView?()
        nonExapndedHeaderViewModel.messageHasChanged(message: message)
        messageBodyViewModel.messageHasChanged(message: message)
        attachmentViewModel.messageHasChanged(message: message)
    }

    func starTapped() {
        messageService.label(messages: [message], label: Message.Location.starred.rawValue, apply: !message.starred)
    }

    func markReadIfNeeded() {
        guard message.unRead else { return }
        messageService.mark(messages: [message], labelID: labelId, unRead: false)
    }

    func downloadDetails() {
        messageService.fetchMessageDetailForMessage(message, labelID: labelId) { [weak self] _, _, _, error in
            guard let self = self else { return }
            self.updateErrorBanner?(error)
            if error != nil && !self.message.isDetailDownloaded {
                self.messageBodyViewModel.messageHasChanged(message: self.message, isError: true)
            }
        }
    }

}

private extension MessageDataService {

    func fetchMessage(messageId: String) -> Message? {
        fetchMessages(withIDs: .init(array: [messageId]), in: CoreDataService.shared.mainContext).first
    }

}

private extension Dictionary where Key == NSAttributedString.Key, Value == Any {

    static var titleAttributes: [Key: Value] {
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center

        return [
            .kern: 0.35,
            .font: font,
            .foregroundColor: UIColorManager.TextNorm,
            .paragraphStyle: paragraphStyle
        ]
    }

}
