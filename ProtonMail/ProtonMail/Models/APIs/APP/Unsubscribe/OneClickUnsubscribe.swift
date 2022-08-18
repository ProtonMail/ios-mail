import ProtonCore_Networking

struct OneClickUnsubscribe: Request {

    private let messageId: MessageID

    init(messageId: MessageID) {
        self.messageId = messageId
    }

    var path: String {
        "/mail/v4/messages/\(messageId.rawValue)/unsubscribe"
    }

    var method: HTTPMethod {
        .post
    }

}
