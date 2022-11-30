// Copyright (c) 2022 Proton AG
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
import ProtonCore_DataModel

final class ToolbarSettingViewModel {
    lazy var listViewToolbarCustomizeViewModel: ToolbarCustomizeViewModel<MessageViewActionSheetAction> = {
        let viewModel = ToolbarCustomizeViewModel<MessageViewActionSheetAction>(
            currentActions: toolbarActionProvider.listViewToolbarActions,
            allActions: MessageViewActionSheetAction.allActionsOfListView(),
            actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
            defaultActions: MessageViewActionSheetAction.defaultActions,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
        )
        return viewModel
    }()
    let currentViewModeToolbarCustomizeViewModel: ToolbarCustomizeViewModel<MessageViewActionSheetAction>

    private let infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider
    private let viewMode: ViewMode
    private let toolbarActionProvider: ToolbarActionProvider
    private let saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase

    init(
        viewMode: ViewMode,
        infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
        toolbarActionProvider: ToolbarActionProvider,
        saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase
    ) {
        self.infoBubbleViewStatusProvider = infoBubbleViewStatusProvider
        self.viewMode = viewMode
        self.toolbarActionProvider = toolbarActionProvider
        self.saveToolbarActionUseCase = saveToolbarActionUseCase
        switch viewMode {
        case .conversation:
            currentViewModeToolbarCustomizeViewModel = .init(
                currentActions: toolbarActionProvider.conversationToolbarActions,
                allActions: MessageViewActionSheetAction.allActionsOfConversationView(),
                actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
                defaultActions: MessageViewActionSheetAction.defaultActions,
                infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
            )
        case .singleMessage:
            currentViewModeToolbarCustomizeViewModel = .init(
                currentActions: toolbarActionProvider.messageToolbarActions,
                allActions: MessageViewActionSheetAction.allActionsOfMessageView(),
                actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
                defaultActions: MessageViewActionSheetAction.defaultActions,
                infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
            )
        }
    }

    func save(completion: @escaping () -> Void) {
        var conversationActions: [MessageViewActionSheetAction]?
        var messageActions: [MessageViewActionSheetAction]?
        switch viewMode {
        case .conversation:
            conversationActions = currentViewModeToolbarCustomizeViewModel.currentActions
        case .singleMessage:
            messageActions = currentViewModeToolbarCustomizeViewModel.currentActions
        }

        let preference: ToolbarActionPreference = .init(
            conversationActions: conversationActions,
            messageActions: messageActions,
            listViewActions: listViewToolbarCustomizeViewModel.currentActions
        )
        saveToolbarActionUseCase
            .callbackOn(.main)
            .executionBlock(params: .init(preference: preference)) { _ in
                completion()
            }
    }

    func infoViewTitle(segment: Int) -> String {
        switch segment {
        case 0:
            return LocalString._toolbar_setting_info_title_message
        case 1:
            return LocalString._toolbar_setting_info_title_inbox
        default:
            assertionFailure("Should not have segment more that 1")
            return ""
        }
    }
}
