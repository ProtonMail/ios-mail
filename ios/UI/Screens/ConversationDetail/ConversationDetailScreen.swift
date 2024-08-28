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

struct ConversationDetailScreen: View {
    @StateObject private var model: ConversationDetailModel
    @State private var animateViewIn: Bool = false

    init(seed: ConversationDetailSeed) {
        self._model = StateObject(wrappedValue: .init(seed: seed))
    }

    var body: some View {
        conversationView
    }

    private var conversationView: some View {
        GeometryReader { proxy in

            ScrollView {
                VStack {
                    conversationDataView
                    ConversationDetailListView(model: model)
                        .frame(maxHeight: .infinity)
                }
                .frame(minHeight: proxy.size.height)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(ConversationDetailScreenIdentifiers.rootItem)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationToolbar(
                purpose: .itemDetail(
                    isStarStateKnown: model.seed.isStarStateKnown,
                    isStarred: model.seed.isStarred
                )
            )
            .opacity(animateViewIn ? 1.0 : 0.0)
            .smoothScreenTransition()
            .task {
                withAnimation(.easeIn) {
                    animateViewIn = true
                }
                await model.fetchInitialData()
            }
        }
    }

    private var conversationDataView: some View {
        VStack(alignment: .leading, spacing: 0) {
            subjectView
                .padding(.top, DS.Spacing.medium)
                .padding(.horizontal, DS.Spacing.large)

            attachmentsAndLabelsView
                .frame(height: 24)
                .padding(.top, DS.Spacing.compact)
                .removeViewIf(model.seed.hasNoAttachments && model.seed.labels.isEmpty)
        }
    }

    private var subjectView: some View {
        Text(model.seed.subject)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.norm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(ConversationDetailScreenIdentifiers.subjectText)
    }

    private var attachmentsAndLabelsView: some View {
        HStack(alignment: .center) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: DS.Spacing.small) {
                    CapsuleView(
                        text: L10n.files(attachmentsCount: model.seed.numAttachments),
                        color: DS.Color.Background.secondary,
                        icon: Image(DS.Icon.icPaperClip),
                        style: .attachment
                    )
                    .removeViewIf(model.seed.hasNoAttachments)

                    ForEach(Array(model.seed.labels.enumerated()), id: \.element.labelId) { _, element in
                        CapsuleView(text: element.text.stringResource, color: element.color, style: .label)
                    }
                    .removeViewIf(model.seed.labels.isEmpty)

                }
            }
            .contentMargins(.horizontal, DS.Spacing.large)
        }
    }
}

private struct ModifiersForSmoothScreenTransition: ViewModifier {

    func body(content: Content) -> some View {
        /**
         With the combination of a white background toolbar and clipping the content to the scrollview area
         we manage to have a nice UI transition from the mailbox to an expanded message that we have to scroll to.
         */
        content
            .toolbarBackground(DS.Color.Background.norm, for: .navigationBar, .tabBar)
            .clipped()
            .background(DS.Color.Background.norm) // has to go before the clipping
    }
}

private extension View {

    func smoothScreenTransition() -> some View {
        self.modifier(ModifiersForSmoothScreenTransition())
    }
}

#Preview("From Mailbox") {

    NavigationView {
        ConversationDetailScreen(seed:
                .mailboxItem(
                    item: .init(
                        id: .init(value: 0),
                        type: .conversation,
                        avatar: .init(initials: "Pf", type: .sender(params: .init())),
                        senders: "",
                        subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia",
                        date: .now,
                        isRead: true,
                        isStarred: true,
                        isSelected: false,
                        isSenderProtonOfficial: true,
                        numMessages: 3,
                        labelUIModel: MailboxLabelUIModel(
                            labelModels: [LabelUIModel(labelId: .init(value: 0), text: "Work", color: .blue)]
                        ),
                        attachmentsUIModel: [
                            .init(id: .init(value: 4), icon: DS.Icon.icFileTypeIconWord, name: "notes.doc")
                        ],
                        expirationDate: nil,
                        snoozeDate: nil
                    ),
                    selectedMailbox: .inbox
                )
        )
    }
}

#Preview("From Notification") {

    NavigationView {
        ConversationDetailScreen(
            seed: .message(
                localID: .init(value: 0),
                subject: "Embarking on an Epic Adventure: Planning Our Team Expedition to Patagonia", sender: "him"
            )
        )
    }
}

private struct ConversationDetailScreenIdentifiers {
    static let rootItem = "detail.rootItem"
    static let subjectText = "detail.subjectText"
}
