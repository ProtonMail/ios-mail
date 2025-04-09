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

import InboxDesignSystem
import SwiftUI

final class EmptySpamTrashBannerStateStore: ObservableObject {
    enum Action {
        case upgradeToAutoDelete
        case emptyLocation
    }
    
    struct State: Equatable {
        let icon: ImageResource
        let title: String
        let buttons: [EmptySpamTrashBanner.ActionButton]
    }
    
    let model: EmptySpamTrashBanner
    @Published var state: State
    
    init(model: EmptySpamTrashBanner) {
        self.model = model
        self.state = model.state
    }
    
    func handle(action: Action) {
        switch action {
        case .upgradeToAutoDelete:
            print("[FIXME]: Implement `Upgrade to Auto-delete` action")
        case .emptyLocation:
            print("[FIXME]: Implement `Empty \(model.location.humanReadable) now` action")
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
                buttons: [.upgradePlan, .emptyLocation]
            )
        case .paidAutoDeleteOn:
            .init(
                icon: DS.Icon.icTrashClock,
                title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
                buttons: [.emptyLocation]
            )
        case .paidAutoDeleteOff:
            .init(
                icon: DS.Icon.icTrash,
                title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOffTitle.string,
                buttons: [.emptyLocation]
            )
        }
    }

}
