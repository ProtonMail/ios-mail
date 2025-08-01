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

import OrderedCollections
import InboxCoreUI
import InboxDesignSystem
import InboxRSVP
import proton_app_uniffi
import SwiftUI

struct MessageBodyView: View {
    @Environment(\.messagePrinter) var messagePrinter: MessagePrinter
    @EnvironmentObject var toastStateStore: ToastStateStore
    let messageID: ID
    let emailAddress: String
    let attachments: [AttachmentDisplayModel]
    let mailbox: Mailbox
    let editScheduledMessage: () -> Void
    let unsnoozeConversation: () -> Void
    @Binding var isBodyLoaded: Bool
    @Binding var attachmentIDToOpen: ID?
    @State var bodyContentHeight: CGFloat = .zero

    init(
        messageID: ID,
        emailAddress: String,
        attachments: [AttachmentDisplayModel],
        mailbox: Mailbox,
        isBodyLoaded: Binding<Bool>,
        attachmentIDToOpen: Binding<ID?>,
        editScheduledMessage: @escaping () -> Void,
        unsnoozeConversation: @escaping () -> Void
    ) {
        self.messageID = messageID
        self.emailAddress = emailAddress
        self.attachments = attachments
        self.mailbox = mailbox
        self._isBodyLoaded = isBodyLoaded
        self._attachmentIDToOpen = attachmentIDToOpen
        self.editScheduledMessage = editScheduledMessage
        self.unsnoozeConversation = unsnoozeConversation
    }

    var body: some View {
        StoreView(
            store: MessageBodyStateStore(
                messageID: messageID,
                mailbox: mailbox,
                wrapper: .productionInstance(),
                toastStateStore: toastStateStore,
                backOnlineActionExecutor: BackOnlineActionExecutor(mailUserSession: { AppContext.shared.userSession })
            )
        ) { state, store in
            VStack(spacing: .zero) {
                if case .loaded(let body) = state.body, let rsvpServiceProvider = body.rsvpServiceProvider {
                    RSVPView(serviceProvider: rsvpServiceProvider)
                }
                if case .loaded(let body) = state.body, !body.banners.isEmpty {
                    MessageBannersView(
                        types: OrderedSet(body.banners),
                        timer: Timer.self,
                        action: { action in
                            switch action {
                            case .editScheduledMessageTapped:
                                editScheduledMessage()
                            case .displayEmbeddedImagesTapped:
                                store.handle(action: .displayEmbeddedImages)
                            case .downloadRemoteContentTapped:
                                store.handle(action: .downloadRemoteContent)
                            case .markAsLegitimateTapped:
                                store.handle(action: .markAsLegitimate)
                            case .unblockSenderTapped:
                                store.handle(action: .unblockSender(emailAddress: emailAddress))
                            case .unsnoozeTapped:
                                unsnoozeConversation()
                            }
                        }
                    )
                }
                if !attachments.isEmpty {
                    MessageBodyAttachmentsView(attachments: attachments, attachmentIDToOpen: $attachmentIDToOpen)
                        .padding(.top, DS.Spacing.extraLarge)
                        .padding([.horizontal, .bottom], DS.Spacing.large)
                }
                MessageBodyHTMLView(bodyContentHeight: $bodyContentHeight, messageBody: state.body)
                    .environment(\.webViewPrintingRegistrar, .init(messagePrinter: messagePrinter, messageID: messageID))
            }
            .alert(model: store.binding(\.alert))
            .onLoad { store.handle(action: .onLoad) }
            .onChange(of: bodyContentHeight) { oldValue, newValue in
                if oldValue.isZero && !newValue.isZero {
                    isBodyLoaded = true
                }
            }
        }
    }
}
