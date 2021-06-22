enum ConversationViewItemType: Equatable {
    case trashedHint
    case header(subject: String)
    case message(viewModel: ConversationMessageViewModel)
    case empty

    static func == (lhs: ConversationViewItemType, rhs: ConversationViewItemType) -> Bool {
        switch (lhs, rhs) {
        case (.trashedHint, .trashedHint):
            return true
        case (.header(let lSubject), .header(let rSubject)):
            return lSubject == rSubject
        case (.message(let lVM), .message(let rVM)):
            return lVM.message.messageID == rVM.message.messageID
        case (.empty, .empty):
            return true
        default:
            return false
        }
    }
}

extension Array where Element == ConversationViewItemType {
    var newestMessage: Message? {
        last { $0.message != nil && $0.message?.draft == false }?.message
    }
}

extension ConversationViewItemType {

    var isEmpty: Bool {
        guard case .empty = self else { return false }
        return true
    }

}
