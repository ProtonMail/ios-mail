protocol ConversationStateServiceDelegate: AnyObject {
    func viewModeHasChanged(viewMode: ViewMode)
    func conversationModeFeatureFlagHasChanged(isFeatureEnabled: Bool)
}
