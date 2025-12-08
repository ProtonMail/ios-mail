// Copyright (c) 2025 Proton Technologies AG
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

import InboxSnapshotTesting
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
struct CustomizeToolbarsScreenSnapshotTests {
    @Test
    func customizeToolbarsScreenLayoutsCorrectly() {
        let sut = CustomizeToolbarsScreen(
            state: .init(
                toolbars: [
                    .list(.init(selected: [.move, .archive, .label, .toggleRead], unselected: [])),
                    .message(.init(selected: [.reply, .move, .forward, .toggleRead], unselected: [])),
                ],
                editToolbar: nil
            ),
            customizeToolbarService: CustomizeToolbarServiceSpy(),
            viewModeProvider: ViewModeProviderStub()
        )

        assertSnapshotsOnIPhoneX(of: sut)
    }
}

final class ViewModeProviderStub: ViewModeProvider {
    var viewModeStub: ViewMode = .conversations

    // MARK: - ViewModeProvider

    func viewMode() async throws -> ViewMode {
        viewModeStub
    }
}

final class CustomizeToolbarServiceSpy: CustomizeToolbarServiceProtocol {
    // MARK: - Stubs

    var getListToolbarActionsStub: [MobileAction] = []
    var getMessageToolbarActionsStub: [MobileAction] = []
    var getConversationToolbarActionsStub: [MobileAction] = []

    var allListActionsStub: [MobileAction] = []
    var allMessageActionsStub: [MobileAction] = []
    var allConversationActionsStub: [MobileAction] = []

    // MARK: - Invocation Tracking

    private(set) var getListToolbarActionsInvokeCount = 0
    private(set) var getMessageToolbarActionsInvokeCount = 0
    private(set) var getConversationToolbarActionsInvokeCount = 0

    private(set) var updateListToolbarActionsInvoked: [[MobileAction]] = []
    private(set) var updateMessageToolbarActionsInvoked: [[MobileAction]] = []
    private(set) var updateConversationToolbarActionsInvoked: [[MobileAction]] = []

    private(set) var getAllListActionsInvokeCount = 0
    private(set) var getAllMessageActionsInvokeCount = 0
    private(set) var getAllConversationActionsInvokeCount = 0

    // MARK: - CustomizeToolbarServiceProtocol

    func getListToolbarActions() async throws(ActionError) -> [MobileAction] {
        getListToolbarActionsInvokeCount += 1
        return getListToolbarActionsStub
    }

    func getMessageToolbarActions() async throws(ActionError) -> [MobileAction] {
        getMessageToolbarActionsInvokeCount += 1
        return getMessageToolbarActionsStub
    }

    func getConversationToolbarActions() async throws(ActionError) -> [MobileAction] {
        getConversationToolbarActionsInvokeCount += 1
        return getConversationToolbarActionsStub
    }

    func updateListToolbarActions(actions: [MobileAction]) async throws(ActionError) {
        updateListToolbarActionsInvoked.append(actions)
    }

    func updateConversationToolbarActions(actions: [MobileAction]) async throws(ActionError) {
        updateConversationToolbarActionsInvoked.append(actions)
    }

    func updateMessageToolbarActions(actions: [MobileAction]) async throws(ActionError) {
        updateMessageToolbarActionsInvoked.append(actions)
    }

    func getAllListActions() -> [MobileAction] {
        getAllListActionsInvokeCount += 1
        return allListActionsStub
    }

    func getAllMessageActions() -> [MobileAction] {
        getAllMessageActionsInvokeCount += 1
        return allMessageActionsStub
    }

    func getAllConversationActions() -> [MobileAction] {
        getAllConversationActionsInvokeCount += 1
        return allConversationActionsStub
    }
}
