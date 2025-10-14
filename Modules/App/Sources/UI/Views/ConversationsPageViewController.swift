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
import proton_app_uniffi
import SwiftUI

struct ConversationsPageViewController: View {
    @Environment(\.presentationMode) var presentationMode

    let startingItem: MailboxItemCellUIModel
    let mailboxCursor: MailboxCursorProtocol

    let draftPresenter: DraftPresenter
    let navigationPath: Binding<NavigationPath>
    let selectedMailbox: SelectedMailbox
    let userSession: MailUserSession
    let customSettings: CustomSettingsProtocol

    @State var activeModel: ConversationDetailModel?
    @State private var isSwipeToAdjacentEnabled: Bool = false

    var body: some View {
        PageViewController(
            cursor: mailboxCursor,
            isSwipeToAdjacentEnabled: isSwipeToAdjacentEnabled,
            startingPage: startingPage,
            pageFactory: pageFactory
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
                    .conversationDetailToolbars(model: activeModel, navigationPath: navigationPath)
            }
        }
        .task {
            do {
                let isEnabled = try await customSettings.swipeToAdjacentConversation().get()
                isSwipeToAdjacentEnabled = isEnabled
            } catch {
                AppLogger.log(error: error, category: .appSettings)
            }
        }
    }

    private func startingPage() -> ConversationDetailScreen {
        pageFactory(model: startingItem)
    }

    private func pageFactory(cursorEntry: CursorEntry) -> ConversationDetailScreen {
        pageFactory(model: cursorEntry.mailboxItemCellUIModel())
    }

    private func pageFactory(model: MailboxItemCellUIModel) -> ConversationDetailScreen {
        .init(
            seed: .mailboxItem(item: model, selectedMailbox: selectedMailbox),
            draftPresenter: draftPresenter,
            navigationPath: navigationPath,
            mailUserSession: userSession,
            onLoad: { if activeModel == nil { activeModel = $0 } },
            onDidAppear: { activeModel = $0 }
        )
    }
}

private extension CursorEntry {
    func mailboxItemCellUIModel() -> MailboxItemCellUIModel {
        switch self {
        case .conversationEntry(let conversation):
            conversation.toMailboxItemCellUIModel(selectedIds: [], showLocation: false)
        case .messageEntry(let message):
            message.toMailboxItemCellUIModel(selectedIds: [], displaySenderEmail: false, showLocation: false)
        }
    }
}
