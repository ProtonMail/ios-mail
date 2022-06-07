import ProtonCore_Common

protocol ConversationStateProviderProtocol: AnyObject {
    var viewMode: ViewMode { get set }
    func add(delegate: ConversationStateServiceDelegate)
}

class ConversationStateService: ConversationStateProviderProtocol {

    var viewMode: ViewMode {
        get {
            isConversationModeEnabled(viewMode: viewModeState, flag: featureFlag) ? .conversation : .singleMessage
        }
        set {
            viewModeState = newValue
        }
    }

    var isConversationFeatureEnabled: Bool {
        featureFlag ?? false
    }

    private let userDefaults: KeyValueStoreProvider
    private let delegatesStore: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    private let featureFlagKey = "conversation_feature_flag"

    private var delegates: [ConversationStateServiceDelegate] {
        delegatesStore.allObjects
            .compactMap { $0 as? ConversationStateServiceDelegate }
    }

    private var viewModeState: ViewMode {
        didSet {
            notifyDelegateIfNeeded(viewMode, old: oldValue)
        }
    }

    private var savedFlag: Bool? {
        get { userDefaults.bool(forKey: featureFlagKey) }
        set {
            if let newValue = newValue {
                userDefaults.set(newValue, forKey: featureFlagKey)
            } else {
                userDefaults.remove(forKey: featureFlagKey)
            }
        }
    }

    private var featureFlag: Bool? {
        didSet {
            savedFlag = featureFlag
            notifyDelegateIfNeeded(featureFlag, old: oldValue)
        }
    }

    init(userDefaults: KeyValueStoreProvider,
         viewMode: ViewMode) {
        self.userDefaults = userDefaults
        self.viewModeState = viewMode
        self.featureFlag = savedFlag
    }

    func add(delegate: ConversationStateServiceDelegate) {
        delegatesStore.add(delegate)
    }

    func userInfoHasChanged(viewMode: ViewMode) {
        guard viewMode != self.viewMode else { return }
        self.viewMode = viewMode
    }

    private func notifyDelegateIfNeeded(_ new: Bool?, old: Bool?) {
        if new != old {
            notifyDelegatesAboutConversationFlagChange()
        }
        let oldValue = isConversationModeEnabled(viewMode: viewMode, flag: old)
        let newValue = isConversationModeEnabled(viewMode: viewMode, flag: new)
        guard oldValue != newValue else { return }
        notifyDelegatesAboutViewModeChange(newViewMode: viewMode)
    }

    private func notifyDelegateIfNeeded(_ new: ViewMode, old: ViewMode) {
        let oldValue = isConversationModeEnabled(viewMode: old, flag: featureFlag)
        let newValue = isConversationModeEnabled(viewMode: new, flag: featureFlag)
        guard oldValue != newValue else { return }
        notifyDelegatesAboutViewModeChange(newViewMode: viewMode)
    }

    private func isConversationModeEnabled(viewMode: ViewMode, flag: Bool?) -> Bool {
        viewMode == .conversation && flag == true
    }

    private func notifyDelegatesAboutConversationFlagChange() {
        delegates
            .forEach { $0.conversationModeFeatureFlagHasChanged(isFeatureEnabled: featureFlag == true) }
    }

    private func notifyDelegatesAboutViewModeChange(newViewMode: ViewMode) {
        delegates
            .forEach { $0.viewModeHasChanged(viewMode: newViewMode) }
    }

}

extension ConversationStateService: FeatureFlagsSubscribeProtocol {
    func handleNewFeatureFlags(_ featureFlags: [String: Any]) {
        if let removeThreadFlag = featureFlags[FeatureFlagKey.threading.rawValue] as? Bool {
            featureFlag = removeThreadFlag
        }
    }
}
