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

@testable import ProtonMail
import Testing

@MainActor
class CustomizeToolbarsStoreTests {
    lazy var viewModeProviderStub = ViewModeProviderStub()
    lazy var customizeToolbarServiceSpy = CustomizeToolbarServiceSpy()

    lazy var sut = CustomizeToolbarsStore(
        state: .initial,
        customizeToolbarService: customizeToolbarServiceSpy,
        viewModeProvider: viewModeProviderStub
    )

    init() {
        customizeToolbarServiceSpy.getListToolbarActionsStub = [.label]
        customizeToolbarServiceSpy.allListActionsStub = [.label, .move]
    }

    @Test
    func editToolbarIsSelected_ItUpdatesPresentationStatus() async {
        await sut.handle(action: .editToolbarSelected(.conversation))

        #expect(sut.state.editToolbar == .conversation)
    }

    @Test
    func onAppear_WhenMessageViewModeIsSet_ItPresentsCorrectToolbarsConfiguration() async {
        viewModeProviderStub.viewModeStub = .messages

        customizeToolbarServiceSpy.getMessageToolbarActionsStub = [.forward]
        customizeToolbarServiceSpy.allMessageActionsStub = [.forward, .reply]

        await sut.handle(action: .onAppear)

        #expect(
            sut.state.toolbars == [
                .list(.init(selected: [.label], unselected: [.move])),
                .message(.init(selected: [.forward], unselected: [.reply])),
            ])
    }

    @Test
    func onAppear_WhenConversationViewModeIsSet_ItPresentsCorrectToolbarsConfiguration() async {
        viewModeProviderStub.viewModeStub = .conversations

        customizeToolbarServiceSpy.getConversationToolbarActionsStub = [.archive]
        customizeToolbarServiceSpy.allConversationActionsStub = [.archive, .trash]

        await sut.handle(action: .onAppear)

        #expect(
            sut.state.toolbars == [
                .list(.init(selected: [.label], unselected: [.move])),
                .conversation(.init(selected: [.archive], unselected: [.trash])),
            ])
    }
}
