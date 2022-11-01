enum ConversationNavigationAction {
    case reply(message: MessageEntity)
    case replyAll(message: MessageEntity)
    case forward(message: MessageEntity)
    case draft(message: MessageEntity)
    case addContact(contact: ContactVO)
    case composeTo(contact: ContactVO)
    case mailToUrl(url: URL)
    case attachmentList(message: MessageEntity, inlineCIDs: [String]?, attachments: [AttachmentInfo])
    case viewHeaders(url: URL)
    case viewHTML(url: URL)
    case viewCypher(url: URL)
    case url(url: URL)
    case inAppSafari(url: URL)
    case addNewLabel
    case addNewFolder
}
