enum ConversationViewItemType {
    case header(subject: String)
    case message(viewModel: ConversationMessageViewModel)
}

private extension ConversationViewItemType {
    var message: Message? {
        guard case .message(let viewModel) = self else {
            return nil
        }
        return viewModel.message
    }
}

extension Array where Element == ConversationViewItemType {
    var newestMessage: Message? {
        last { $0.message != nil && $0.message?.draft == false }?.message
    }
}
