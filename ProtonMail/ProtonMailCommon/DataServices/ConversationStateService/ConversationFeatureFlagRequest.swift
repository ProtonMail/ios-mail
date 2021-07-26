import ProtonCore_Networking

struct ConversationFeatureFlagRequest: Request {

    var path: String {
        "/core/v4/features/ThreadingIOS"
    }

    var method: HTTPMethod {
        .get
    }

}
