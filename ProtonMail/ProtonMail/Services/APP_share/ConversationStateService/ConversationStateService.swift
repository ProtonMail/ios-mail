
// sourcery: mock
protocol ConversationStateProviderProtocol: AnyObject {
    var viewMode: ViewMode { get set }
    func add(delegate: ConversationStateServiceDelegate)
}

class ConversationStateService: ConversationStateProviderProtocol {

    var viewMode: ViewMode {
        didSet {
            guard viewMode != oldValue else { return }
            notifyDelegatesAboutViewModeChange(newViewMode: viewMode)
        }
    }

    private let delegatesStore: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    private var delegates: [ConversationStateServiceDelegate] {
        delegatesStore.allObjects.compactMap { $0 as? ConversationStateServiceDelegate }
    }

    init(viewMode: ViewMode) {
        self.viewMode = viewMode
    }

    func add(delegate: ConversationStateServiceDelegate) {
        delegatesStore.add(delegate)
    }

    func userInfoHasChanged(viewMode: ViewMode) {
        guard viewMode != self.viewMode else { return }
        self.viewMode = viewMode
    }

    private func notifyDelegatesAboutViewModeChange(newViewMode: ViewMode) {
        delegates.forEach { $0.viewModeHasChanged(viewMode: newViewMode) }
    }
}
