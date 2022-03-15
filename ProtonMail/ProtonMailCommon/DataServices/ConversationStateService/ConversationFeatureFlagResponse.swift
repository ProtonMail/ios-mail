import ProtonCore_Networking

class ConversationFeatureFlagResponse: Response {

    var isConversationModeEnabled: Bool?

    override func ParseResponse(_ response: [String: Any]) -> Bool {
        guard let feature = response["Feature"] as? [String: Any],
              let value = feature["Value"] as? Bool else { return false }
        isConversationModeEnabled = value
        return true
    }

}
