import ProtonCore_Networking

struct MarkAsUnsubscribed: Request {

    private let messageId: MessageID

    init(messageId: MessageID) {
        self.messageId = messageId
    }

    var path: String {
        "/mail/v4/messages/mark/unsubscribed"
    }

    var method: HTTPMethod {
        .put
    }

    var parameters: [String: Any]? {
        [
            "IDs": [messageId.rawValue]
        ]
    }

}
