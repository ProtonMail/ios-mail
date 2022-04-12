// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

class SettingsConversationViewModel {

    var isConversationModeEnabled: Bool {
        didSet { conversationViewModeHasChanged?(isConversationModeEnabled) }
    }

    var conversationViewModeHasChanged: ((Bool) -> Void)?
    var isLoading: ((Bool) -> Void)?
    var requestFailed: ((NSError) -> Void)?

    private let updateViewModeService: ViewModeUpdater
    private let conversationStateService: ConversationStateProviderProtocol
    private let eventService: EventsFetching

    init(conversationStateService: ConversationStateProviderProtocol,
         updateViewModeService: ViewModeUpdater,
         eventService: EventsFetching) {
        self.conversationStateService = conversationStateService
        self.updateViewModeService = updateViewModeService
        self.isConversationModeEnabled = conversationStateService.viewMode == .conversation
        self.eventService = eventService
        conversationStateService.add(delegate: self)
    }

    func switchValueHasChanged(isOn: Bool, completion: (() -> Void)? = nil) {
        isLoading?(true)

        updateViewModeService.update(viewMode: isOn ? .conversation : .singleMessage) { [weak self] result in
            switch result {
            case .success(let viewMode):
                self?.handleNewViewMode(viewMode: viewMode)
                self?.isLoading?(false)
                self?.eventService.fetchEvents(
                    byLabel: Message.Location.allmail.rawValue,
                    notificationMessageID: nil,
                    completion: { _, _, _ in
                        completion?()
                    })
            case .failure(let error):
                self?.requestFailed?(error as NSError)
                self?.conversationViewModeHasChanged?(self?.isConversationModeEnabled ?? false)
                completion?()
            }
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
