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
import Testing

@MainActor
final class EmptySpamTrashBannerStateStoreTests {
    var sut: EmptySpamTrashBannerStateStore!
    let toastStateStore = ToastStateStore(initialState: .initial)
    
    // MARK: - `.upgradeToAutoDelete` action

    @Test
    func testState_WhenUpgradeToAutoDeleteAction_ItDoesNotUpdateTheStateAndPresentsComingSoon() {
        sut = makeSUT(.spam, .freePlan)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.freeUserTitle.string,
            buttons: [.upgradePlan, .emptyLocation],
            alert: .none
        ))
        #expect(toastStateStore.state.toasts == [])
        
        sut.handle(action: .upgradeToAutoDelete)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.freeUserTitle.string,
            buttons: [.upgradePlan, .emptyLocation],
            alert: .none
        ))
        #expect(toastStateStore.state.toasts == [.comingSoon])
    }
    
    // MARK: - `.emptyLocation` action
    
    @Test
    func testState_WhenEmptyTrashLocationAction_ItPresentsEmptyLocationConfirmationAlert() {
        sut = makeSUT(.trash, .paidAutoDeleteOn)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .none
        ))
        
        sut.handle(action: .emptyLocation)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .emptyLocationConfirmation(location: .trash, action: { _ in })
        ))
    }
    
    @Test
    func testState_WhenCancelAlertActionTapped_ItDismissesAlert() throws {
        sut = makeSUT(.trash, .paidAutoDeleteOn)
        
        sut.handle(action: .emptyLocation)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .emptyLocationConfirmation(location: .trash, action: { _ in })
        ))
        
        let cancelAction = try sut.state.alertAction(for: .cancel)
        cancelAction.action()
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .none
        ))
    }
    
    @Test
    func testState_WhenConfirmAlertActionTapped_ItDismissesAlertAndPresentsComingSoon() throws {
        sut = makeSUT(.trash, .paidAutoDeleteOn)
        
        sut.handle(action: .emptyLocation)
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .emptyLocationConfirmation(location: .trash, action: { _ in })
        ))
        #expect(toastStateStore.state.toasts == [])
        
        let deleteAction = try sut.state.alertAction(for: .delete)
        deleteAction.action()
        
        #expect(sut.state == .init(
            icon: DS.Icon.icTrashClock,
            title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
            buttons: [.emptyLocation],
            alert: .none
        ))
        #expect(toastStateStore.state.toasts == [.comingSoon])
    }
    
    private func makeSUT(
        _ location: EmptySpamTrashBanner.Location,
        _ userState: EmptySpamTrashBanner.UserState
    ) -> EmptySpamTrashBannerStateStore {
        .init(model: .init(location: location, userState: userState), toastStateStore: toastStateStore)
    }
}

private extension EmptySpamTrashBannerStateStore.State {
    
    func alertAction(for action: DeleteConfirmationAlertAction) throws -> AlertAction {
        try #require(alert?.actions.findFirst(for: action.info.title, by: \.title))
    }

}
