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

import ProtonCore_UIFoundations

class SingleMessageViewModel {

    var message: Message {
        didSet {
            propagateMessageData()
        }
    }

    let contentViewModel: SingleMessageContentViewModel
    private(set) lazy var userActivity: NSUserActivity = .messageDetailsActivity(messageId: message.messageID)

    private let messageService: MessageDataService
    let user: UserManager
    let labelId: String
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

    init(labelId: String,
         message: Message,
         user: UserManager,
         childViewModels: SingleMessageChildViewModels,
         internetStatusProvider: InternetConnectionStatusProvider) {
        self.labelId = labelId
        self.message = message
        self.messageService = user.messageService
        self.user = user
        self.messageObserver = MessageObserver(messageId: message.messageID, messageService: messageService)
        let contentContext = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            areBottomButtonsVisible: false
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
            self?.message = $0
        }
    }

    func propagateMessageData() {
        refreshView?()
        contentViewModel.messageHasChanged(message: message)
    }

    func starTapped() {
        messageService.label(messages: [message], label: Message.Location.starred.rawValue, apply: !message.starred)
    }

    func getActionTypes() -> [MailboxViewModel.ActionTypes] {
        var actions: [MailboxViewModel.ActionTypes] = []
        let isHavingMoreThanOneContact = (message.toList.toContacts() + message.ccList.toContacts()).count > 1
        actions.append(isHavingMoreThanOneContact ? .replyAll : .reply)
        actions.append(.readUnread)
        let deleteLocation = [
            Message.Location.draft.rawValue,
            Message.Location.spam.rawValue,
            Message.Location.trash.rawValue
        ]
        actions.append(deleteLocation.contains(labelId) ? .delete : .trash)
        actions.append(.more)
        return actions
    }

    func handleActionBarAction(_ action: MailboxViewModel.ActionTypes) {
        switch action {
        case .delete:
            messageService.delete(messages: [message], label: labelId)
        case .readUnread:
            messageService.mark(messages: [message], labelID: labelId, unRead: !message.unRead)
        case .trash:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.trash.rawValue,
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
                                to: Message.Location.trash.rawValue,
                                queue: true)
        case .archive:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.archive.rawValue,
                                queue: true)
        case .spam:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.spam.rawValue,
                                queue: true)
        case .delete:
            messageService.delete(messages: [message], label: labelId)
        case .reportPhishing:
            let messageBody = contentViewModel.messageBodyViewModel.body
            BugDataService(api: self.user.apiService).reportPhishing(messageID: message.messageID,
                                                                     messageBody: messageBody
                                                                        ?? LocalString._error_no_object) { _ in
                self.messageService.move(messages: [self.message],
                                         from: [self.labelId],
                                         to: Message.Location.spam.rawValue,
                                         queue: true)
                completion()
            }
            return
        case .inbox, .spamMoveToInbox:
            messageService.move(messages: [message],
                                from: [labelId],
                                to: Message.Location.inbox.rawValue,
                                queue: true)
        default:
            break
        }
        completion()
    }

    func getMessageHeaderUrl() -> URL? {
        let message = contentViewModel.messageBodyViewModel.message
        let time = dateFormatter.string(from: message.time ?? Date())
        let title = message.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let filename = "headers-" + time + "-" + title.joined(separator: "-")
        guard let header = message.header else {
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
        guard let body = try? messageService.decryptBodyIfNeeded(message: message) else {
            return nil
        }
        return try? self.writeToTemporaryUrl(body, filename: filename)
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

    func handleMoveToAction(messages: [Message]) {
        guard let destination = selectedMoveToFolder else { return }
        messageService.move(messages: messages, to: destination.location.labelID, queue: true)
    }

    func handleMoveToAction(conversations: [Conversation]) {
        fatalError("Not implemented")
    }
}

// MARK: - Label as functions
extension SingleMessageViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(messages: [Message],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, status) in currentOptionsStatus {
            guard status != .dash else { continue } // Ignore the option in dash
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID }) {
                // Add to message which does not have this label
                if !message.contains(label: label.location.labelID) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: true)
                }
            } else {
                if message.contains(label: label.location.labelID) {
                    messageService.label(messages: messages,
                                         label: label.location.labelID,
                                         apply: false)
                }
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            if let fLabel = message.firstValidFolder() {
                messageService.move(messages: messages,
                                    from: [fLabel],
                                    to: Message.Location.archive.rawValue)
            }
        }
    }

    func handleLabelAsAction(conversations: [Conversation],
                             shouldArchive: Bool,
                             currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        fatalError("Not implemented")
    }
}

private extension MessageDataService {

    func fetchMessage(messageId: String) -> Message? {
        fetchMessages(withIDs: .init(array: [messageId]), in: CoreDataService.shared.mainContext).first
    }

}
