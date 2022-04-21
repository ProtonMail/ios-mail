extension ConversationViewItemType {

    var message: MessageEntity? {
        messageViewModel?.message
    }

    var messageViewModel: ConversationMessageViewModel? {
        guard case let .message(viewModel) = self else { return nil }
        return viewModel
    }

}
