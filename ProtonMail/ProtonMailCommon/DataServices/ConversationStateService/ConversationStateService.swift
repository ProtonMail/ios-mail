import ProtonCore_Common

class ConversationStateService {

    var viewMode: ViewMode {
        get {
            return .singleMessage
//            isConversationModeEnabled(viewMode: viewModeState, flag: featureFlag) ? .conversation : .singleMessage
        }
        set {
            viewModeState = newValue
        }
    }

    var isConversationFeatureEnabled: Bool {
        return false
    }

    private let conversationFeatureFlagService: ConversationFeatureFlagService
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

    init(conversationFeatureFlagService: ConversationFeatureFlagService,
         userDefaults: KeyValueStoreProvider,
         viewMode: ViewMode) {
        self.conversationFeatureFlagService = conversationFeatureFlagService
        self.userDefaults = userDefaults
        self.viewModeState = viewMode
        self.featureFlag = savedFlag
        refreshFlag()
    }

    func add(delegate: ConversationStateServiceDelegate) {
        delegatesStore.add(delegate)
    }

    func refreshFlag() {
        _ = conversationFeatureFlagService.getConversationFlag()
            .done { [weak self] in self?.featureFlag = $0 }
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
