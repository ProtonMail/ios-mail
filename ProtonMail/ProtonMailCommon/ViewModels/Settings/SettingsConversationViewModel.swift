import PromiseKit

class SettingsConversationViewModel {

    var isConversationModeEnabled: Bool {
        didSet { conversationViewModeHasChanged?(isConversationModeEnabled) }
    }

    var conversationViewModeHasChanged: ((Bool) -> Void)?
    var isLoading: ((Bool) -> Void)?
    var requestFailed: ((NSError) -> Void)?

    private let updateViewModeService: UpdateViewModeService
    private let conversationStateService: ConversationStateService

    init(conversationStateService: ConversationStateService,
         updateViewModeService: UpdateViewModeService) {
        self.conversationStateService = conversationStateService
        self.updateViewModeService = updateViewModeService
        self.isConversationModeEnabled = conversationStateService.viewMode == .conversation
        conversationStateService.add(delegate: self)
    }

    func switchValueHasChanged(isOn: Bool) {
        isLoading?(true)
        _ = updateViewModeService.update(viewMode: isOn ? .conversation : .singleMessage)
            .done { [weak self] in self?.handleNewViewMode(viewMode: $0) }
            .ensure { [weak self] in self?.isLoading?(false) }
            .catch { [weak self] in
                self?.requestFailed?($0 as NSError)
                self?.conversationViewModeHasChanged?(self?.isConversationModeEnabled ?? false)
            }
    }

    private func handleNewViewMode(viewMode: ViewMode?) {
        isConversationModeEnabled = viewMode == .conversation
        guard let viewMode = viewMode else { return }
        conversationStateService.viewMode = viewMode
    }

}

extension SettingsConversationViewModel: ConversationStateServiceDelegate {

    func viewModeHasChanged(viewMode: ViewMode) {
        isConversationModeEnabled = viewMode == .conversation
    }

    func conversationModeFeatureFlagHasChanged(isFeatureEnabled: Bool) {}

}
