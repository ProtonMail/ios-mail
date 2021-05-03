import PMCommon

struct OneClickUnsubscribe: Request {

    private let messageId: String

    init(messageId: String) {
        self.messageId = messageId
    }

    var path: String {
        "/mail/v4/messages/\(messageId)/unsubscribe"
    }

    var method: HTTPMethod {
        .post
    }

}
