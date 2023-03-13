// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_TestingToolkit
@testable import ProtonMail

class MockConversationViewModel: ConversationViewModel {

    override init(labelId: LabelID, conversation: ConversationEntity, coordinator: ConversationCoordinatorProtocol, user: UserManager, contextProvider: CoreDataContextProviderProtocol, internetStatusProvider: InternetConnectionStatusProvider, conversationStateProvider: ConversationStateProviderProtocol, labelProvider: LabelProviderProtocol, userIntroductionProgressProvider: UserIntroductionProgressProvider, targetID: MessageID?, toolbarActionProvider: ToolbarActionProvider, saveToolbarActionUseCase: SaveToolbarActionSettingsForUsersUseCase, toolbarCustomizeSpotlightStatusProvider: ToolbarCustomizeSpotlightStatusProvider, goToDraft: @escaping (MessageID, OriginalScheduleDate?) -> Void, dependencies: ConversationViewModel.Dependencies) {
        super.init(labelId: labelId, conversation: conversation, coordinator: coordinator, user: user, contextProvider: contextProvider, internetStatusProvider: internetStatusProvider, conversationStateProvider: conversationStateProvider, labelProvider: labelProvider, userIntroductionProgressProvider: userIntroductionProgressProvider, targetID: targetID, toolbarActionProvider: toolbarActionProvider, saveToolbarActionUseCase: saveToolbarActionUseCase, toolbarCustomizeSpotlightStatusProvider: toolbarCustomizeSpotlightStatusProvider, goToDraft: goToDraft, dependencies: dependencies)
    }

    @FuncStub(MockConversationViewModel.fetchConversationDetails) var callFetchConversationDetail
    override func fetchConversationDetails(completion: (() -> Void)?) {
        callFetchConversationDetail(completion)
    }

    @FuncStub(MockConversationViewModel.searchForScheduled) var callSearchForScheduled
    override func searchForScheduled(conversation: ConversationEntity? = nil, displayAlert: @escaping (Int) -> Void, continueAction: @escaping () -> Void) {
        callSearchForScheduled(conversation, displayAlert, continueAction)
    }

    @FuncStub(MockConversationViewModel.handleActionSheetAction(_:completion:)) var callHandleActionSheetAction
    override func handleActionSheetAction(_ action: MessageViewActionSheetAction, completion: @escaping () -> Void) {
        callHandleActionSheetAction(action, completion)
    }
}
