import ProtonCore_Common

// sourcery: mock
protocol ConversationStateProviderProtocol: AnyObject {
    var viewMode: ViewMode { get set }
    func add(delegate: ConversationStateServiceDelegate)
}

class ConversationStateService: ConversationStateProviderProtocol {

    var viewMode: ViewMode {
        get {
            isConversationModeEnabled(viewMode: viewModeState) ? .conversation : .singleMessage
        }
        set {
            viewModeState = newValue
        }
    }

    private let delegatesStore: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    private var delegates: [ConversationStateServiceDelegate] {
        delegatesStore.allObjects.compactMap { $0 as? ConversationStateServiceDelegate }
    }

    private var viewModeState: ViewMode {
        didSet {
            notifyDelegateIfNeeded(viewMode, old: oldValue)
        }
    }

    init(viewMode: ViewMode) {
        self.viewModeState = viewMode
    }

    func add(delegate: ConversationStateServiceDelegate) {
        delegatesStore.add(delegate)
    }

    func userInfoHasChanged(viewMode: ViewMode) {
        guard viewMode != self.viewMode else { return }
        self.viewMode = viewMode
    }

    private func notifyDelegateIfNeeded(_ new: ViewMode, old: ViewMode) {
        let oldValue = isConversationModeEnabled(viewMode: old)
        let newValue = isConversationModeEnabled(viewMode: new)
        guard oldValue != newValue else { return }
        notifyDelegatesAboutViewModeChange(newViewMode: viewMode)
    }

    private func isConversationModeEnabled(viewMode: ViewMode) -> Bool {
        viewMode == .conversation
    }

    private func notifyDelegatesAboutViewModeChange(newViewMode: ViewMode) {
        delegates.forEach { $0.viewModeHasChanged(viewMode: newViewMode) }
    }
}
