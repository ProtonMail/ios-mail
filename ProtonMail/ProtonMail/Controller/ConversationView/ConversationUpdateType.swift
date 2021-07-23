enum ConversationUpdateType {
    case willUpdate
    case didUpdate(messages: [Message])
    case insert(row: Int)
    case update(message: Message, fromRow: Int, toRow: Int)
    case move(fromRow: Int, toRow: Int)
    case delete(row: Int)
}
