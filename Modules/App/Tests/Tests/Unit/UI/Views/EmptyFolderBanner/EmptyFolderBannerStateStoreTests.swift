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
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import Testing

@MainActor
final class EmptyFolderBannerStateStoreTests {
    var sut: EmptyFolderBannerStateStore!
    let toastStateStore = ToastStateStore(initialState: .initial)
    private let wrapperSpy = RustWrappersSpy()
    
    // MARK: - `.upgradeToAutoDelete` action

    @Test
    func testState_WhenUpgradeToAutoDeleteAction_ItDoesNotUpdateTheStateAndPresentsComingSoon() {
        sut = makeSUT(.spam, .freePlan)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.freeUserTitle.string,
            buttons: [.upgradePlan, .emptyLocation],
            alert: .none
        ))
        #expect(toastStateStore.state.toasts == [])
        
        sut.handle(action: .upgradeToAutoDelete)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.freeUserTitle.string,
            buttons: [.upgradePlan, .emptyLocation],
            alert: .none
        ))
        #expect(toastStateStore.state.toasts == [.comingSoon])
    }
    
    // MARK: - `.emptyFolder` action
    
    @Test
    func testState_WhenEmptyTrashFolderAction_ItPresentsEmptyFolderConfirmationAlert() {
        sut = makeSUT(.trash, .paidAutoDeleteOn)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .none
        ))
        
        sut.handle(action: .emptyFolder)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .emptyFolderConfirmation(folder: .trash, action: { _ in })
        ))
    }
    
    @Test
    func testState_WhenCancelAlertActionTapped_ItDismissesAlert() throws {
        sut = makeSUT(.trash, .paidAutoDeleteOn)
        
        sut.handle(action: .emptyFolder)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .emptyFolderConfirmation(folder: .trash, action: { _ in })
        ))
        
        let cancelAction = try sut.state.alertAction(for: .cancel)
        cancelAction.action()
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .none
        ))
    }
    
    @Test
    func testState_WhenConfirmAlertActionTapped_ItDismissesAlertAndTriggersDeletionAllMessages() throws {
        let labelID: ID = .init(value: 99)
        sut = makeSUT(.trash, .paidAutoDeleteOn, labelID)
        
        sut.handle(action: .emptyFolder)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .emptyFolderConfirmation(folder: .trash, action: { _ in })
        ))
        #expect(wrapperSpy.deleteAllCalls == [])
        
        let deleteAction = try sut.state.alertAction(for: .delete)
        deleteAction.action()
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .none
        ))
        #expect(wrapperSpy.deleteAllCalls == [labelID])
    }
    
    private func makeSUT(
        _ folder: EmptyFolderBanner.Folder,
        _ userState: EmptyFolderBanner.UserState,
        _ labelID: ID = .random()
    ) -> EmptyFolderBannerStateStore {
        .init(
            model: .init(folder: .init(labelID: labelID, type: folder), userState: userState),
            toastStateStore: toastStateStore,
            mailUserSession: .dummy,
            wrapper: wrapperSpy.testingInstance
        )
    }
}

private extension EmptyFolderBannerStateStore.State {
    
    func alertAction(for action: DeleteConfirmationAlertAction) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: action.info.title, by: \.title))
    }

}

private class RustWrappersSpy {
    var stubbedDeleteAllResult: VoidActionResult!
    private(set) var deleteAllCalls: [ID] = []
    
    private(set) lazy var testingInstance = RustEmptyFolderBannerWrapper(
        deleteAllMessages: { [unowned self] _, labelID in
            deleteAllCalls.append(labelID)
            return stubbedDeleteAllResult
        }
    )
}
