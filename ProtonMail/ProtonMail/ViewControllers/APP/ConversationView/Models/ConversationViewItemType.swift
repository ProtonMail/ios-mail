import Darwin
enum ConversationViewItemType: Equatable {
    case trashedHint
    case header(subject: String)
    case message(viewModel: ConversationMessageViewModel)

    static func == (lhs: ConversationViewItemType, rhs: ConversationViewItemType) -> Bool {
        switch (lhs, rhs) {
        case (.trashedHint, .trashedHint):
            return true
        case let (.header(lSubject), .header(rSubject)):
            return lSubject == rSubject
        case let (.message(lVM), .message(rVM)):
            return lVM.message.messageID == rVM.message.messageID
        default:
            return false
        }
    }
}

extension Array where Element == ConversationViewItemType {
    var newestMessage: MessageEntity? {
        if let msg = last(where: { $0.message != nil && $0.message?.isDraft == false })?.message {
            return msg
        } else {
            return nil
        }
    }

    func isLatestMessageUnread(location labelID: LabelID) -> Bool {
        return last(where: {
            $0.message?.contains(labelID: labelID) == true &&
            $0.message?.isDraft == false
        })?.message?.unRead == true
    }
}
