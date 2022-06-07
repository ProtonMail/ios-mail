import ProtonCore_Networking

class UpdateViewModeResponse: Response {

    var viewMode: ViewMode?

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        guard let mailSettings = response["MailSettings"] as? [String: Any],
              let viewModeValue = mailSettings["ViewMode"] as? Int else { return false }
        self.viewMode = ViewMode(rawValue: viewModeValue)
        return true
    }

}
