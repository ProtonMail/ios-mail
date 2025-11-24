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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

struct ConversationDetailScreen: View {
    @StateObject private var model: ConversationDetailModel
    @State private var animateViewIn: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.proceedAfterMove) var proceedAfterMove
    private let draftPresenter: DraftPresenter
    private let mailUserSession: MailUserSession
    private let onLoad: (ConversationDetailModel) -> Void
    private let onDidAppear: (ConversationDetailModel) -> Void

    init(
        seed: ConversationDetailSeed,
        draftPresenter: DraftPresenter,
        mailUserSession: MailUserSession,
        onLoad: @escaping (ConversationDetailModel) -> Void,
        onDidAppear: @escaping (ConversationDetailModel) -> Void
    ) {
        self._model = StateObject(
            wrappedValue: .init(
                seed: seed,
                draftPresenter: draftPresenter,
                backOnlineActionExecutor: .init(mailUserSession: { mailUserSession }),
                snoozeService: SnoozeService(mailUserSession: { mailUserSession })
            ))
        self.draftPresenter = draftPresenter
        self.mailUserSession = mailUserSession
        self.onLoad = onLoad
        self.onDidAppear = onDidAppear
    }

    var body: some View {
        conversationView
            .onLoad {
                onLoad(model)
            }
            .onDidAppear {
                onDidAppear(model)
            }
            .actionSheetsFlow(
                mailbox: { model.mailbox.unsafelyUnwrapped },
                mailUserSession: mailUserSession,
                state: $model.actionSheets,
                goBackNavigation: proceedAfterMove
            )
            .sheet(
                item: $model.actionSheets.editToolbar,
                content: { toolbarType in
                    EditToolbarScreen(
                        state: .initial(toolbarType: toolbarType),
                        customizeToolbarService: mailUserSession
                    )
                }
            )
            .alert(model: $model.actionAlert)
            .fullScreenCover(item: $model.attachmentIDToOpen) { id in
                AttachmentView(config: .init(id: id, mailbox: model.mailbox.unsafelyUnwrapped))
                    .edgesIgnoringSafeArea([.top, .bottom])
            }
            .onChange(
                of: model.state,
                { _, newValue in
                    if case .messagesReady(let messageListState) = newValue, messageListState.messages.isEmpty {
                        proceedAfterMove()
                    }
                }
            )
            .onLoad {
                model.configure(colorScheme: colorScheme)
            }
            .onChange(
                of: colorScheme,
                { _, newValue in
                    model.configure(colorScheme: newValue)
                }
            )
            .environment(\.messageAppearanceOverrideStore, model.messageAppearanceOverrideStore)
            .environment(\.messagePrinter, model.messagePrinter)
    }

    private var conversationView: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {
                    ListHeaderView(isHeaderVisible: $model.isHeaderVisible, parentGeometry: proxy) {
                        subjectView
                            .padding(.top, DS.Spacing.medium)
                            .padding(.horizontal, DS.Spacing.large)
                    }
                    if let hiddenMessageBanner {
                        BannerView(model: hiddenMessageBanner)
                    }
                    ConversationDetailListView(
                        model: model,
                        mailUserSession: mailUserSession,
                        draftPresenter: draftPresenter,
                        editToolbar: {},
                        goBack: proceedAfterMove
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(ConversationDetailScreenIdentifiers.rootItem)
            }
            .opacity(animateViewIn ? 1.0 : 0.0)
            .background(DS.Color.Background.norm)
            .task {
                withAnimation(.easeIn) {
                    animateViewIn = true
                }
                await model.fetchInitialData()
            }
        }
    }

    private var hiddenMessageBanner: Banner? {
        guard let messageListState = model.state.messageListState else {
            return nil
        }

        switch messageListState.hiddenMessagesBannerState {
        case .none:
            return nil
        case .some(let state):
            switch state.bannerVariant {
            case .containsTrashedMessages:
                return .trashed(isOn: hiddenMessagesBannerBinding)
            case .containsNonTrashedMessages:
                return .nonTrashed(isOn: hiddenMessagesBannerBinding)
            }
        }
    }

    private var hiddenMessagesBannerBinding: Binding<Bool> {
        .init(
            get: { model.state.isHiddenMessagesBannerOn },
            set: { newValue in model.setConversationHiddenMessagesBannerVisible(value: newValue) }
        )
    }

    private var subjectView: some View {
        Text(model.seed.subject)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.norm)
            .multilineTextAlignment(.center)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityIdentifier(ConversationDetailScreenIdentifiers.subjectText)
    }
}

#Preview("From Mailbox") {
    NavigationView {
        ConversationDetailScreen(
            seed: .mailboxItem(
                item: .init(
                    id: .random(),
                    conversationID: .random(),
                    type: .conversation,
                    avatar: .init(
                        info: .init(initials: "Pf", color: .blue),
                        type: .sender(.init(params: .init(), blocked: .no))
                    ),
                    emails: "",
                    subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia",
                    date: .now,
                    location: nil,
                    locationIcon: nil,
                    isRead: true,
                    isStarred: true,
                    isSelected: false,
                    isSenderProtonOfficial: true,
                    messagesCount: 3,
                    labelUIModel: MailboxLabelUIModel(
                        labelModels: [LabelUIModel(labelId: .init(value: 0), text: "Work", color: .blue)]
                    ),
                    attachments: .init(
                        previewables: [
                            .init(id: .init(value: 4), icon: DS.Icon.icFileTypeIconWord, name: "notes.doc")
                        ],
                        containsCalendarInvitation: false,
                        totalCount: 2
                    ),
                    expirationDate: nil,
                    snoozeDate: nil,
                    isDraftMessage: false,
                    shouldUseSnoozedColorForDate: false
                ),
                selectedMailbox: .inbox
            ),
            draftPresenter: .dummy(),
            mailUserSession: .dummy,
            onLoad: { _ in },
            onDidAppear: { _ in }
        )
    }
}

#Preview("From Notification") {
    NavigationView {
        ConversationDetailScreen(
            seed: .pushNotification(
                .init(
                    remoteId: .init(value: ""),
                    subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia"
                )),
            draftPresenter: .dummy(),
            mailUserSession: .dummy,
            onLoad: { _ in },
            onDidAppear: { _ in }
        )
    }
}

private struct ConversationDetailScreenIdentifiers {
    static let rootItem = "detail.rootItem"
    static let subjectText = "detail.subjectText"
}

extension ConversationDetailSeed {

    var isOutbox: Bool {
        switch self {
        case .mailboxItem(_, let selectedMailbox):
            selectedMailbox.systemFolder == .outbox
        case .pushNotification, .searchResultItem:
            false
        }
    }

}
