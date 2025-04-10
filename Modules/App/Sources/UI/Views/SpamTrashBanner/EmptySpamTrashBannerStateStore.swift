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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

final class EmptySpamTrashBannerStateStore: ObservableObject {
    enum Action {
        case upgradeToAutoDelete
        case emptyLocation
        case deleteConfirmed(DeleteConfirmationAlertAction)
    }
    
    struct State: Equatable, Copying {
        let icon: ImageResource
        let title: String
        let buttons: [EmptySpamTrashBanner.ActionButton]
        var alert: AlertModel?
    }
    
    let model: EmptySpamTrashBanner
    @Published var state: State
    private let toastStateStore: ToastStateStore
    
    init(model: EmptySpamTrashBanner, toastStateStore: ToastStateStore) {
        self.model = model
        self.state = model.state
        self.toastStateStore = toastStateStore
    }
    
    func handle(action: Action) {
        switch action {
        case .upgradeToAutoDelete:
            toastStateStore.present(toast: .comingSoon)
        case .emptyLocation:
            let alert: AlertModel = .emptyLocationConfirmation(
                location: model.location,
                action: { [weak self] action in self?.handle(action: .deleteConfirmed(action)) }
            )
            
            state = state.copy(\.alert, to: alert)
        case .deleteConfirmed(let action):
            switch action {
            case .cancel:
                state = state.copy(\.alert, to: nil)
            case .delete:
                toastStateStore.present(toast: .comingSoon)
                state = state.copy(\.alert, to: nil)
            }
        }
    }
}

private extension EmptySpamTrashBanner {

    var state: EmptySpamTrashBannerStateStore.State {
        switch userState {
        case .freePlan:
            .init(
                icon: DS.Icon.icTrashClock,
                title: L10n.EmptySpamTrashBanner.freeUserTitle.string,
                buttons: [.upgradePlan, .emptyLocation],
                alert: .none
            )
        case .paidAutoDeleteOn:
            .paidNoAlert(
                icon: DS.Icon.icTrashClock,
                title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle
            )
        case .paidAutoDeleteOff:
            .paidNoAlert(
                icon: DS.Icon.icTrash,
                title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOffTitle
            )
        }
    }

}

private extension EmptySpamTrashBannerStateStore.State {

    static func paidNoAlert(icon: ImageResource, title: LocalizedStringResource) -> Self {
        .init(icon: icon, title: title.string, buttons: [.emptyLocation], alert: .none)
    }

}
