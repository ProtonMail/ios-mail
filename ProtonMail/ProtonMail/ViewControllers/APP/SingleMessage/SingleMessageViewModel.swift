//
//  SingleMessageViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
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

import ProtonCore_UIFoundations

class SingleMessageViewModel {

    var message: MessageEntity {
        didSet {
            propagateMessageData()
        }
    }

    let contentViewModel: SingleMessageContentViewModel
    private(set) lazy var userActivity: NSUserActivity = .messageDetailsActivity(messageId: message.messageID)

    private let messageService: MessageDataService
    let user: UserManager
    let labelId: LabelID
    private let messageObserver: MessageObserver

    var refreshView: (() -> Void)?

    var selectedMoveToFolder: MenuLabel?
    var selectedLabelAsLabels: Set<LabelLocation> = Set()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    init(labelId: LabelID,
         message: MessageEntity,
         user: UserManager,
         childViewModels: SingleMessageChildViewModels,
         internetStatusProvider: InternetConnectionStatusProvider
    ) {
        self.labelId = labelId
        self.message = message
        self.messageService = user.messageService
        self.user = user
        self.messageObserver = MessageObserver(messageId: message.messageID, messageService: messageService)
        let contentContext = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .singleMessage
        )
        self.contentViewModel = SingleMessageContentViewModel(
            context: contentContext,
            childViewModels: childViewModels,
            user: user,
            internetStatusProvider: internetStatusProvider
        )
    }

    var messageTitle: NSAttributedString {
        message.title.apply(style: FontManager.MessageHeader.alignment(.center))
    }

    func viewDidLoad() {
        messageObserver.observe { [weak self] in
            self?.message = MessageEntity($0)
        }
    }

    func propagateMessageData() {
        refreshView?()
        contentViewModel.messageHasChanged(message: message)
    }

    func starTapped() {
        messageService.label(messages: [message],
                             label: Message.Location.starred.labelID,
                             apply: !message.isStarred)
    }

    func handleToolBarAction(_ action: MailboxViewModel.ActionTypes) {
        switch action {
        case .delete:
            messageService.delete(messages: [message], label: labelId)
        case .markAsRead:
            messageService.mark(messages: [message], labelID: labelId, unRead: false)
        case .markAsUnread:
            messageService.mark(messages: [message], labelID: labelId, unRead: true)
        case .trash:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.trash.labelID,
                                queue: true)
        default:
            return
        }
    }

    func handleActionSheetAction(_ action: MessageViewActionSheetAction,
                                 completion: @escaping () -> Void) {
        switch action {
        case .markUnread:
            messageService.mark(messages: [message], labelID: labelId, unRead: true)
        case .trash:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.trash.labelID,
                                queue: true)
        case .archive:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.archive.labelID,
                                queue: true)
        case .spam:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.spam.labelID,
                                queue: true)
        case .delete:
            messageService.delete(messages: [message],
                                  label: labelId)
        case .reportPhishing:
            reportPhishing(completion)
            return
        case .inbox, .spamMoveToInbox:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.inbox.labelID,
                                queue: true)
        case .viewInDarkMode:
            contentViewModel.messageBodyViewModel.reloadMessageWith(style: .dark)
            return
        case .viewInLightMode:
            contentViewModel.messageBodyViewModel.reloadMessageWith(style: .lightOnly)
            return
        default:
            break
        }
        completion()
    }

    private func reportPhishing(_ completion: @escaping () -> Void) {
        let displayMode = contentViewModel.messageBodyViewModel.displayMode
        let messageBody = contentViewModel.messageBodyViewModel.bodyParts?.body(for: displayMode)
        self.user.reportService.reportPhishing(messageID: message.messageID,
                                               messageBody: messageBody ?? LocalString._error_no_object) { _ in
            self.messageService.move(messages: [self.message],
                                     from: [self.labelId],
                                     to: Message.Location.spam.labelID,
                                     queue: true)
            completion()
        }
    }

    func getMessageHeaderUrl() -> URL? {
        let message = contentViewModel.messageBodyViewModel.message
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "headers-" + time + "-" + title.joined(separator: "-")
        guard let header = message.rawHeader else {
            assert(false, "No header in message")
            return nil
        }
        return try? self.writeToTemporaryUrl(header, filename: filename)
    }

    func getMessageBodyUrl() -> URL? {
        let message = contentViewModel.messageBodyViewModel.message
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "body-" + time + "-" + title.joined(separator: "-")
        guard let decryptedPair = try? messageService.messageDecrypter.decrypt(message: message) else {
            return nil
        }
        let body = decryptedPair.0
        return try? self.writeToTemporaryUrl(body, filename: filename)
    }

    func toolbarActionTypes() -> [MailboxViewModel.ActionTypes] {
        var types: [MailboxViewModel.ActionTypes] = [
            .markAsUnread,
            .trash,
            .delete,
            .moveTo,
            .labelAs,
            .more
        ]
        let originMessageListIsSpamOrTrash = [
            Message.Location.spam.labelID,
            Message.Location.trash.labelID
        ].contains(labelId)

        if message.isTrash || message.isSpam || originMessageListIsSpamOrTrash {
            types.removeAll(where: { $0 == .trash })
        } else {
            types.removeAll(where: { $0 == .delete })
        }
        return types
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectoryUrl
            .appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try content.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }
}

// MARK: - Move to functions
extension SingleMessageViewModel: MoveToActionSheetProtocol {

    func handleMoveToAction(messages: [MessageEntity], isFromSwipeAction: Bool) {
        guard let destination = selectedMoveToFolder else { return }
        messageService.move(messages: messages, to: destination.location.labelID, queue: true)
    }

    func handleMoveToAction(conversations: [ConversationEntity], isFromSwipeAction: Bool, completion: (() -> Void)?) {
        fatalError("Not implemented")
    }
}

// MARK: - Label as functions
extension SingleMessageViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [MessageEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.rawLabelID == label.location.rawLabelID }) {
                // Add to message which does not have this label
                if !message.contains(location: label.location) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: true)
                }
            } else {
                if message.contains(location: label.location) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: false)
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = message.getFirstValidFolder() {
                messageService.move(messages: messages,
                                    from: [fLabel],
                                    to: Message.Location.archive.labelID)
            }
        }
    }

    func handleLabelAsAction(conversations: [ConversationEntity],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType],
                             completion: (() -> Void)?) {
        fatalError("Not implemented")
    }
}
