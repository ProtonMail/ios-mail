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
    private let toolbarActionProvider: ToolbarActionProvider
    private let saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase

    init(
        infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
        toolbarActionProvider: ToolbarActionProvider,
        saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase
    ) {
        self.infoBubbleViewStatusProvider = infoBubbleViewStatusProvider
        self.toolbarActionProvider = toolbarActionProvider
        self.saveToolbarActionUseCase = saveToolbarActionUseCase
        currentViewModeToolbarCustomizeViewModel = .init(
            currentActions: toolbarActionProvider.messageToolbarActions,
            allActions: MessageViewActionSheetAction.allActionsOfMessageView(),
            actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
            defaultActions: MessageViewActionSheetAction.defaultActions,
            infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
        )
    }

    func save(completion: @escaping () -> Void) {
        let messageActions = currentViewModeToolbarCustomizeViewModel.currentActions
        let preference: ToolbarActionPreference = .init(
            messageActions: messageActions,
            listViewActions: listViewToolbarCustomizeViewModel.currentActions
        )
        saveToolbarActionUseCase
            .callbackOn(.main)
            .execute(params: .init(preference: preference)) { _ in
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
