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
import proton_app_uniffi
import SwiftUI

// we might be able to remove this view once we use MailboxCursor in the push notification flow
struct PagelessConversationDetailScreen: View {
    @Environment(\.presentationMode) var presentationMode

    let seed: ConversationDetailSeed
    let draftPresenter: DraftPresenter
    let mailUserSession: MailUserSession

    @State var activeModel: ConversationDetailModel?

    var body: some View {
        ConversationDetailScreen(
            seed: seed,
            draftPresenter: draftPresenter,
            mailUserSession: mailUserSession,
            onLoad: { activeModel = $0 },
            onDidAppear: { _ in }
        )
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    action: {
                        presentationMode.wrappedValue.dismiss()
                    },
                    label: {
                        Image(symbol: .chevronLeft)
                            .foregroundStyle(DS.Color.Icon.norm)
                    }
                )
                .square(size: 40)
            }
        }
        .background {
            if let activeModel {
                Color
                    .clear
                    .conversationDetailToolbars(model: activeModel)
            }
        }
    }
}
