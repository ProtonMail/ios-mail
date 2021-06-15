import ProtonCore_UIFoundations

extension ConversationViewModel {

    func handleActionSheetAction(_ action: MessageViewActionSheetAction,
                                 message: Message,
                                 completion: @escaping () -> Void) {
        guard let messageLocation = message.messageLocation?.rawValue else { return }
        switch action {
        case .markUnread:
            messageService.mark(messages: [message], labelID: messageLocation, unRead: true)
        case .trash:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.trash.rawValue,
                                queue: true)
        case .archive:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.archive.rawValue,
                                queue: true)
        case .spam:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.spam.rawValue,
                                queue: true)
        case .delete:
            messageService.delete(messages: [message], label: messageLocation)
        case .reportPhishing:
            let messageBody = message.body
            BugDataService(api: self.user.apiService).reportPhishing(
                messageID: message.messageID,
                messageBody: messageBody) { _ in
                    self.messageService.move(messages: [message],
                                             from: [messageLocation],
                                             to: Message.Location.spam.rawValue,
                                             queue: true)
                    completion()
            }
            return
        case .inbox, .spamMoveToInbox:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.inbox.rawValue,
                                queue: true)
        default:
            break
        }
        completion()
    }

}
