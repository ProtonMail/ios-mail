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
import proton_app_uniffi
import DesignSystem

struct MessageConversationActionsSheet: View {
    @StateObject var model: MessageConversationActionsModel

    init(model: MessageConversationActionsModel) {
        _model = .init(wrappedValue: model)
    }

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: DS.Spacing.standard) {
                    HStack(spacing: DS.Spacing.standard) {
                        ForEach(model.state.availableActions.replyActions, id: \.self) { action in
                            replyButton(action: action)
                        }
                    }
                    section {
                        ForEachLast(data: model.state.availableActions.messageConversationActions) { action, isLast in
                            listButton(
                                title: action.displayData.title,
                                image: action.displayData.image,
                                isLast:  isLast
                            )
                        }
                    }

                    section { // FIXME: - Move to actions
                        listButton(title: L10n.Action.moveTo, image: DS.Icon.icFolderArrowIn, isLast: false)
                    }

                    section {
                        ForEachLast(data: model.state.availableActions.generalActions) { action, isLast in
                            listButton(title: action.displayData.title, image: action.displayData.image, isLast: isLast)
                        }
                    }
                }.padding(.all, DS.Spacing.large)
            }
            .background(DS.Color.Background.secondary)
            .navigationTitle(model.state.title)
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.loadActions() }
        }
    }

    private func section<Content: View>(content: () -> Content) -> some View {
        VStack(spacing: .zero) {
            content()
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }

    private func replyButton(action: ReplyAction) -> some View {
        Button(action: { print("Action: \(action.displayData.title) tapped") }) {
            VStack(spacing: DS.Spacing.standard) {
                Image(action.displayData.image)
                    .resizable()
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Icon.norm)
                Text(action.displayData.title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.weak)
            }
            .frame(height: 84)
            .frame(maxWidth: .infinity)
        }
        .background(DS.Color.BackgroundInverted.secondary)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }

    private func listButton(title: LocalizedStringResource, image: ImageResource, isLast: Bool) -> some View {
        VStack(spacing: .zero) {
            Button(action: { print("Action") }) {
                HStack(spacing: DS.Spacing.large) {
                    Image(image)
                        .resizable()
                        .square(size: 20)
                        .foregroundStyle(DS.Color.Icon.norm)
                    Text(title)
                        .foregroundStyle(DS.Color.Text.weak)
                    Spacer()
                }
                .frame(height: 52)
                .padding(.leading, DS.Spacing.large)
            }
            if !isLast {
                Divider()
                    .frame(height: 1)
            }
        }
    }

}

#Preview {
    MessageConversationActionsSheet(model: MessageConversationActionsSheetPreviewProvider.testData())
}

enum MessageConversationActionsSheetPreviewProvider {
    static func testData() -> MessageConversationActionsModel {
        let model = MessageConversationActionsModel(
            mailbox: .init(noPointer: .init()),
            input: .init(ids: [], type: .message, title: "Hello".notLocalized)
        )
        model.state = .init(
            title: "Hello".notLocalized,
            availableActions: .init(
                replyActions: [.reply, .forward, .replyAll],
                messageConversationActions: [.markUnread, .star, .pin, .labelAs],
                moveActions: [
                    .init(
                        localId: .random(),
                        name: .trash,
                        isSelected: .unselected
                    ),
                ],
                generalActions: [
                    .viewMessageInLightMode,
                    .saveAsPdf,
                    .print,
                    .viewHeaders,
                    .viewHtml,
                    .reportPhishing
                ]
            )
        )
        return model
    }
}
