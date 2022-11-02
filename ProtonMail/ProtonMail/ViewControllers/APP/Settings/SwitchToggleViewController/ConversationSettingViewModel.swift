// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import struct UIKit.CGFloat

final class ConversationSettingViewModel: SwitchToggleVMProtocol {
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }

    private let updateViewModeService: ViewModeUpdater
    private let conversationStateService: ConversationStateProviderProtocol
    private let eventService: EventsFetching

    init(updateViewModeService: ViewModeUpdater,
         conversationStateService: ConversationStateProviderProtocol,
         eventService: EventsFetching) {
        self.updateViewModeService = updateViewModeService
        self.conversationStateService = conversationStateService
        self.eventService = eventService
    }
}

extension ConversationSettingViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        let newMode: ViewMode = newStatus ? .conversation : .singleMessage
        guard newMode != conversationStateService.viewMode else {
            completion(nil)
            return
        }
        updateViewModeService.update(viewMode: newMode) { [weak self] result in
            switch result {
            case .success(let viewMode):
                self?.eventService.fetchEvents(
                    byLabel: Message.Location.allmail.labelID,
                    notificationMessageID: nil,
                    completion: nil
                )
                if let viewMode = viewMode {
                    self?.conversationStateService.viewMode = viewMode
                }
                completion(nil)
            case .failure(let error):
                completion(error as NSError)
            }
        }
    }
}

extension ConversationSettingViewModel: SwitchToggleVMOutput {
    var title: String { LocalString._conversation_settings_title }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { 1 }
    var headerTopPadding: CGFloat { 8 }
    var footerTopPadding: CGFloat { 8 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        (LocalString._conversation_settings_row_title, conversationStateService.viewMode == .conversation)
    }

    func sectionHeader(of section: Int) -> String? {
        nil
    }

    func sectionFooter(of section: Int) -> String? {
        LocalString._conversation_settings_footer_title
    }
}
