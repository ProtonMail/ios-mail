enum ConversationUpdateType {
    case willUpdate
    case didUpdate(messages: [MessageEntity])
    case insert(row: Int)
    case update(message: MessageEntity)
    case move(fromRow: Int, toRow: Int)
    case delete(row: Int, messageID: MessageID)
}
