enum ConversationViewItemType {
    case header(subject: String)
    case message(viewModel: ConversationMessageViewModel)
    case empty
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
