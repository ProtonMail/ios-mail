// Copyright (c) 2024 Proton Technologies AG
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

import SwiftUI

struct MailboxTopBarView: View {
    let state: MailboxTopBarState
    let onEvent: (MailboxTopBarEvent) -> Void

    var body: some View {
        if #available(iOS 26, *) {
            LiquidGlassTopBar(state: state, onEvent: onEvent)
        } else {
            LegacyTopBar(state: state, onEvent: onEvent)
        }
    }
}

#Preview {
    struct Preview: View {
        @State var stateSelectAllAvailable: MailboxTopBarState = .selectionMode(.canSelectMoreItems)
        @State var stateSelectAllAllSelected: MailboxTopBarState = .selectionMode(.noMoreItemsToSelect)
        @State var stateSelectAllDisabled: MailboxTopBarState = .selectionMode(.selectionLimitReached)
        var body: some View {
            VStack {
                MailboxTopBarView(state: stateSelectAllAvailable) { _ in }
                MailboxTopBarView(state: stateSelectAllAllSelected) { _ in }
                MailboxTopBarView(state: stateSelectAllDisabled) { _ in }
            }
            .border(.red)
        }
    }

    return Preview()
}
