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
import Combine
import Testing

@MainActor
class EditToolbarStoreTests {
    var cancellables = Set<AnyCancellable>()
    let customizeToolbarServiceSpy = CustomizeToolbarServiceSpy()
    let refreshToolbarNotifier = RefreshToolbarNotifier()

    func makeSUT(toolbarType: ToolbarType, dismiss: @escaping () -> Void) -> EditToolbarStore {
        .init(
            state: .initial(toolbarType: toolbarType),
            customizeToolbarService: customizeToolbarServiceSpy,
            refreshToolbarNotifier: refreshToolbarNotifier,
            dismiss: dismiss
        )
    }

    @Test
    func listActions_ItUpdatesStateCorrectly() async {
        customizeToolbarServiceSpy.allMessageActionsStub = [.reply, .forward, .spam, .archive, .move]
        customizeToolbarServiceSpy.getMessageToolbarActionsStub = [.reply]

        var refreshEventReceived: [ToolbarType] = []

        refreshToolbarNotifier
            .refreshToolbar
            .sink(receiveValue: { refreshEventReceived.append($0) })
            .store(in: &cancellables)

        var dismissInvokeCount = 0

        let sut = makeSUT(toolbarType: .message) {
            dismissInvokeCount += 1
        }

        await sut.handle(action: .onLoad)

        #expect(
            sut.state.toolbarActions.current
                == .init(
                    selected: [.reply],
                    unselected: [.forward, .spam, .archive, .move]
                ))

        await sut.handle(action: .addToSelectedTapped(actionToAdd: .spam))

        #expect(
            sut.state.toolbarActions.current
                == .init(
                    selected: [.spam, .reply],
                    unselected: [.forward, .archive, .move]
                ))

        await sut.handle(action: .actionsReordered(fromOffsets: IndexSet(integersIn: 0..<1), toOffset: 2))

        #expect(
            sut.state.toolbarActions.current
                == .init(
                    selected: [.reply, .spam],
                    unselected: [.forward, .archive, .move]
                ))

        await sut.handle(action: .removeFromSelectedTapped(actionToRemove: .reply))

        #expect(
            sut.state.toolbarActions.current
                == .init(
                    selected: [.spam],
                    unselected: [.reply, .forward, .archive, .move]
                ))

        await sut.handle(action: .saveTapped)

        #expect(customizeToolbarServiceSpy.updateMessageToolbarActionsInvoked == [[.spam]])
        #expect(refreshEventReceived == [.message])
    }

    @Test
    func resetToOriginalIsTapped_ItSetsDefaultActionsAsSelected() async {
        customizeToolbarServiceSpy.allMessageActionsStub = [.reply, .forward, .spam, .archive, .move]
        customizeToolbarServiceSpy.getMessageToolbarActionsStub = [.reply]

        let sut = makeSUT(toolbarType: .message) {}

        await sut.handle(action: .onLoad)

        await sut.handle(action: .resetToOriginalTapped)

        #expect(
            sut.state.toolbarActions.current
                == .init(
                    selected: [.toggleRead, .trash, .move, .label],
                    unselected: [.forward, .spam, .archive, .move]
                ))
    }

    @Test
    func cancelIsTapped_ItDismissedScreen() async {
        var dismissInvokeCount = 0

        let sut = makeSUT(toolbarType: .message) {
            dismissInvokeCount += 1
        }

        await sut.handle(action: .cancelTapped)

        #expect(dismissInvokeCount == 1)
    }
}
