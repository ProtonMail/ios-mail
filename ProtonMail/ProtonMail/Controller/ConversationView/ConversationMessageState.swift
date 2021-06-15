enum ConversationMessageState {
    case collapsed(viewModel: ConversationCollapsedMessageViewModel)
    case expanded(viewModel: ConversationExpandedMessageViewModel)
}

extension ConversationMessageState {

    var collapsedViewModel: ConversationCollapsedMessageViewModel? {
        guard case let .collapsed(viewModel) = self else { return nil }
        return viewModel
    }

    var expandedViewModel: ConversationExpandedMessageViewModel? {
        guard case let .expanded(viewModel) = self else { return nil }
        return viewModel
    }

}
