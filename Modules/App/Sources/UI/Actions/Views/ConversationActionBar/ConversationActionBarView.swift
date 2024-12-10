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

import proton_app_uniffi
import SwiftUI

struct ConversationActionBarView: View {
    @StateObject var store: ConversationActionBarStateStore

    init(
        conversationID: ID,
        bottomBarConversationActionsProvider: @escaping ConversationBottomBarActionsProvider,
        mailbox: Mailbox,
        handleAction: @escaping (BottomBarAction) -> Void
    ) {
        self._store = StateObject(wrappedValue: .init(
            conversationID: conversationID,
            bottomBarConversationActionsProvider: bottomBarConversationActionsProvider,
            mailbox: mailbox,
            handleAction: handleAction
        ))
    }

    var body: some View {
        BottomActionBarView(actions: store.state) { action in
            store.handle(action: .actionSelected(action))
        }
        .onLoad {
            store.handle(action: .onLoad)
        }
    }
}

#Preview {
    ConversationActionBarViewPreviewDataProvider.view()
}
