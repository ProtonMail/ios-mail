extension ConversationViewItemType {

    var message: Message? {
        messageViewModel?.message
    }

    var messageViewModel: ConversationMessageViewModel? {
        guard case let .message(viewModel) = self else { return nil }
        return viewModel
    }

}
