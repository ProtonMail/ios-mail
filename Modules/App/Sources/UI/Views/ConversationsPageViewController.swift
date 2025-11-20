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
import proton_app_uniffi

struct ConversationsPageViewController: View {
    @Environment(\.presentationMode) var presentationMode

    let startingItem: ConversationDetailSeed
    let makeMailboxCursor: (ID) async -> MailboxCursorProtocol?
    let modelToSeedMapping: (MailboxItemCellUIModel, SelectedMailbox) -> ConversationDetailSeed

    let draftPresenter: DraftPresenter
    let selectedMailbox: SelectedMailbox
    let userSession: MailUserSession

    @State var activeModel: ConversationDetailModel?
    @State private var isSwipeToAdjacentEnabled: Bool = false
    @State private var mailboxCursor: MailboxCursorProtocol?

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
                    .conversationDetailToolbars(model: activeModel)
            }
        }
        .task {
            do {
                let customSettings = customSettings(ctx: userSession)
                let isEnabled = try await customSettings.swipeToAdjacentConversation().get()
                isSwipeToAdjacentEnabled = isEnabled
            } catch {
                AppLogger.log(error: error, category: .appSettings)
            }
        }
        .onChange(of: activeModel?.conversationItem) { _, item in
            if let item {
                updateCursor(itemID: item.id)
            }
        }
    }

    private func startingPage() -> ConversationDetailScreen {
        pageFactory(seed: startingItem)
    }

    private func pageFactory(cursorEntry: CursorEntry) -> ConversationDetailScreen {
        pageFactory(model: cursorEntry.mailboxItemCellUIModel())
    }

    private func pageFactory(model: MailboxItemCellUIModel) -> ConversationDetailScreen {
        pageFactory(seed: modelToSeedMapping(model, selectedMailbox))
    }

    private func pageFactory(seed: ConversationDetailSeed) -> ConversationDetailScreen {
        .init(
            seed: seed,
            draftPresenter: draftPresenter,
            mailUserSession: userSession,
            onLoad: { if activeModel == nil { activeModel = $0 } },
            onDidAppear: { newActiveModel in
                activeModel = newActiveModel

                if let itemID = newActiveModel.conversationItem?.id {
                    updateCursor(itemID: itemID)
                }
            }
        )
    }

    private func updateCursor(itemID: ID) {
        guard mailboxCursor == nil else {
            return
        }

        Task {
            let mailboxCursor = await makeMailboxCursor(itemID)

            if self.mailboxCursor == nil {
                self.mailboxCursor = mailboxCursor
            }
        }
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
