import ProtonCore_Networking

struct UpdateViewModeRequest: Request {

    private let viewMode: ViewMode

    var path: String {
        "/mail/v4/settings/viewmode"
    }

    var method: HTTPMethod {
        .put
    }

    var parameters: [String : Any]? {
        [
            "ViewMode": viewMode.rawValue
        ]
    }

    init(viewMode: ViewMode) {
        self.viewMode = viewMode
    }

}
