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
import ProtonCoreDataModel

final class ToolbarSettingViewModel {
    typealias Dependencies = ToolbarCustomizeViewModel<MessageViewActionSheetAction>.Dependencies
    & HasSaveToolbarActionSettings
    & HasToolbarActionProvider
    & HasUserManager

    lazy var listViewToolbarCustomizeViewModel: ToolbarCustomizeViewModel<MessageViewActionSheetAction> = {
        let viewModel = ToolbarCustomizeViewModel<MessageViewActionSheetAction>(
            currentActions: dependencies.toolbarActionProvider.listViewToolbarActions,
            allActions: MessageViewActionSheetAction.allActionsOfListView(),
            dependencies: dependencies
        )
        return viewModel
    }()
    let currentViewModeToolbarCustomizeViewModel: ToolbarCustomizeViewModel<MessageViewActionSheetAction>

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        let allActions = MessageViewActionSheetAction.allActionsOfMessageView()

        currentViewModeToolbarCustomizeViewModel = .init(
            currentActions: dependencies.toolbarActionProvider.messageToolbarActions,
            allActions: allActions,
            dependencies: dependencies
        )
    }

    func save(completion: @escaping () -> Void) {
        let messageActions = currentViewModeToolbarCustomizeViewModel.currentActions
        let preference: ToolbarActionPreference = .init(
            messageActions: messageActions,
            listViewActions: listViewToolbarCustomizeViewModel.currentActions
        )
        dependencies.saveToolbarActionSettings
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
