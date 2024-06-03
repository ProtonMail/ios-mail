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

import DesignSystem
import SwiftUI

struct ConversationScreen: View {
    @StateObject private var model: ConversationModel
    init(seed: ConversationScreenSeedUIModel) {
        self._model = StateObject(wrappedValue: .init(seed: seed))
    }

    var body: some View {
        GeometryReader { proxy in

            ScrollView {
                VStack {
                    VStack(spacing: 0) {
                        subjectView
                            .padding(.top, DS.Spacing.standard)
                            .padding(.horizontal, DS.Spacing.large)

                        attachmentsView
                            .padding(.top, DS.Spacing.medium)
                            .padding(.leading, DS.Spacing.large)
                            .removeViewIf(model.seed.numAttachments < 1)
                    }
                    VStack(spacing: 0) {

                        switch model.state {
                        case .initial:
                            EmptyView()
                        case .fetchingMessages:
                            ProgressView()
                                .padding(.top, DS.Spacing.large)
                        case .messagesReady(let previous, let last):
                            messageList(previous: previous, last: last)
                                .padding(.top, DS.Spacing.large)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(minHeight: proxy.size.height)
            }
            .navigationBarTitleDisplayMode(.inline)
            .mailboxItemDetailToolbar(
                isStarStateKnown: model.seed.isStarStateKnown,
                isStarred: model.seed.isStarred
            )
            .smoothScreenTransition()
            .task {
                await model.fetchData()
            }
        }
    }

    private var subjectView: some View {
        Text(model.seed.subject)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.norm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attachmentsView: some View {
        HStack {
            Image(uiImage: DS.Icon.icPaperClip)
                .resizable()
                .frame(width: 14, height: 14)
                .foregroundColor(DS.Color.Icon.weak)
            Text("\(model.seed.numAttachments) \(LocalizationTemp.Plurals.file)")
                .font(.caption)
                .foregroundColor(DS.Color.Text.weak)
            Spacer()
        }
    }

    private func messageList(previous: [MessageCellUIModel], last: ExpandedMessageCellUIModel) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollView in
                LazyVStack(spacing: 0) {
                    ForEach(Array(previous.enumerated()), id: \.1.id) { index, model in
                        switch model.type {
                        case .collapsed(let uiModel):
                            CollapsedMessageCell(uiModel: uiModel, isFirstCell: index == 0)
                                .id(uiModel.messageId)
                        case .expanded(let uiModel):
                            ExpandedMessageCell(uiModel: uiModel, isFirstCell: index == 0)
                                .id(uiModel.messageId)
                        }
                    }
                }
                ExpandedMessageCell(uiModel: last, isFirstCell: previous.isEmpty)
                    .id(last.messageId)
                    .task {
                        scrollView.scrollTo(model.focusedMessageOnAppear, anchor: .top)
                    }
            }
        }
    }
}

private struct ModifiersForSmoothScreenTransition: ViewModifier {

    func body(content: Content) -> some View {
        /**
         With the combination of a white background toolbar and clipping the content to th scrollview area
         we manage to have a nice UI transition from the mailbox to an expanded message that we have to scroll to.
         */
        content
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar, .tabBar)
            .clipped()
    }
}

private extension View {

    func smoothScreenTransition() -> some View {
        self.modifier(ModifiersForSmoothScreenTransition())
    }
}

#Preview("From Mailbox") {

    NavigationView {
        ConversationScreen(seed:
                .mailboxItem(
                    .init(
                        id: 0,
                        type: .conversation,
                        avatar: .init(initials: "Pf", senderImageParams: .init()),
                        senders: "",
                        subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia",
                        date: .now,
                        isRead: true,
                        isStarred: true,
                        isSelected: false,
                        isSenderProtonOfficial: true,
                        numMessages: 3,
                        labelUIModel: .init(),
                        attachmentsUIModel: [.init(attachmentId: 4, icon: DS.Icon.icFileTypeIconWord, name: "notes.doc")],
                        expirationDate: nil,
                        snoozeDate: nil
                    )
                )
        )
    }
}

#Preview("From Notification") {

    NavigationView {
        ConversationScreen(seed: .pushNotification(messageId: "0", subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia", sender: "him"))
    }
}
