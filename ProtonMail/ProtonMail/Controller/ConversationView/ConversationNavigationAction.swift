enum ConversationNavigationAction {
    case reply(message: Message)
    case replyAll(message: Message)
    case forward(message: Message)
    case draft(message: Message)
    case addContact(contact: ContactVO)
    case composeTo(contact: ContactVO)
    case mailToUrl(url: URL)
    case attachmentList(message: Message, inlineCIDs: [String]?)
    case viewHeaders(url: URL)
    case viewHTML(url: URL)
    case url(url: URL)
    case addNewLabel
    case addNewFolder
}
