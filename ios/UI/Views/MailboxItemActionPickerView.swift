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

struct MailboxItemActionPickerView: View {
    private let mailboxItemIdentifier: MailboxItemIdentifier
    private let isSingleRecipient: Bool
    private let resolver: MailboxItemActionResolver

    var onActionTap: (_ action: Action, _ item: MailboxItemIdentifier) -> ()

    init(
        mailboxItemIdentifier: MailboxItemIdentifier,
        isSingleRecipient: Bool,
        actionResolverParams: ConditionalActionResolverParams,
        onActionTap: @escaping (_ action: Action, _ item: MailboxItemIdentifier) -> ()
    ) {
        self.mailboxItemIdentifier = mailboxItemIdentifier
        self.isSingleRecipient = isSingleRecipient
        self.resolver = MailboxItemActionResolver(params: actionResolverParams)
        self.onActionTap = onActionTap
    }

    var body: some View {
        VStack(spacing: DS.Spacing.medium) {
            replyActionButtons
            actionList
        }
        .padding(.top, DS.Spacing.large)
        .background(DS.Color.Background.secondary)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var replyActionButtons: some View {
        if mailboxItemIdentifier.type == .conversation {
            EmptyView()
        } else {

            HStack {
                replyActionButton(name: LocalizationTemp.MessageAction.reply, icon: DS.Icon.icReplay)
                replyActionButton(name: LocalizationTemp.MessageAction.replyAll, icon: DS.Icon.icReplayAll)
                    .removeViewIf(isSingleRecipient)
                replyActionButton(name: LocalizationTemp.MessageAction.forward, icon: DS.Icon.icForward)
            }
            .padding(.horizontal, 20)
            .clipped()
        }
    }

    private func replyActionButton(name: String, icon: UIImage) -> some View {
        Button {

        } label: {
            SendActionButtonStack(isSingleRecipient: isSingleRecipient) {
                Image(uiImage: icon)
                    .iconModifier()

                Text(name)
                    .lineLimit(1)
                    .font(DS.Font.body3)
                    .foregroundStyle(DS.Color.Text.weak)
            }
        }
        .background(DS.Color.Background.norm)
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }

    @MainActor
    private var actionList: some View {
        List {
            section(actions: MailboxItemActionPickerSection.first.actions(type: mailboxItemIdentifier.type))
            section(actions: MailboxItemActionPickerSection.second.actions(type: mailboxItemIdentifier.type))
            section(actions: MailboxItemActionPickerSection.third.actions(type: mailboxItemIdentifier.type))
        }
        .customListRemoveTopInset()
        .listSectionSpacing(DS.Spacing.medium)
    }

    private func section(actions: [MailboxItemAction]) -> some View {
        Section {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, itemAction in
                messageActionCell(for: resolver.action(for: itemAction))
                    .customListLeadingSeparator()
            }
            .listRowBackground(DS.Color.Background.norm)
        }
    }

    private func messageActionCell(for action: Action) -> some View {
        Button(action: {
            onActionTap(action, mailboxItemIdentifier)
        }, label: {
            HStack(spacing: DS.Spacing.large) {
                Image(uiImage: action.icon)
                    .iconModifier()

                Text(action.name)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.Text.weak)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        })
        .buttonStyle(BorderlessButtonStyle())
    }
}

private enum MailboxItemActionPickerSection {

    case first
    case second
    case third

    func actions(type: MailboxItemType) -> [MailboxItemAction] {
        switch self {
        case .first:
            if type == .message {
                [
                    .conditional(.toggleReadStatus),
                    .conditional(.toggleStarStatus),
                    .action(.labelAs)
                ]
            } else {
                [
                    .conditional(.toggleReadStatus),
                    .action(.snooze),
                    .conditional(.toggleStarStatus),
                    .action(.labelAs)
                ]
            }
        case .second:
            [
                .conditional(.moveToTrash),
                .conditional(.moveToArchive),
                .action(.moveToSpam),
                .action(.moveTo)
            ]
        case .third:
            if type == .message {
                [
                    .action(.renderInLightMode),
                    .action(.saveAsPDF),
                    .action(.print),
                    .action(.viewHeaders),
                    .action(.viewHTML),
                    .action(.reportPhishing)
                ]
            } else {
                [
                    .action(.saveAsPDF),
                    .action(.print),
                    .action(.reportPhishing)
                ]
            }
        }
    }
}

private struct SendActionButtonStack<Content: View>: View {
    let isSingleRecipient: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        if isSingleRecipient {
            HStack(spacing: DS.Spacing.medium, content: content)
                .frame(maxWidth: .infinity, maxHeight: 52)
        } else {
            VStack(spacing: DS.Spacing.standard, content: content)
                .frame(maxWidth: .infinity, maxHeight: 80)
        }
    }
}

private extension Image {

    func iconModifier() -> some View {
        self
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(DS.Color.Icon.norm)
    }
}

#Preview("Message and single recipient") {
    let params = ConditionalActionResolverParams(
        selectionReadStatus: .allRead,
        selectionStarStatus: .allStarred,
        systemFolder: nil
    )
    return MailboxItemActionPickerView(
        mailboxItemIdentifier: .message(1),
        isSingleRecipient: true,
        actionResolverParams: params,
        onActionTap: { _, _ in }
    )
}

#Preview("Message and multiple recipients") {
    let params = ConditionalActionResolverParams(
        selectionReadStatus: .noneRead,
        selectionStarStatus: .noneStarred,
        systemFolder: nil
    )
    return MailboxItemActionPickerView(
        mailboxItemIdentifier: .message(1),
        isSingleRecipient: false,
        actionResolverParams: params,
        onActionTap: { _, _ in }
    )
}

#Preview("Conversation") {
    let params = ConditionalActionResolverParams(
        selectionReadStatus: .allRead,
        selectionStarStatus: .allStarred,
        systemFolder: nil
    )
    return MailboxItemActionPickerView(
        mailboxItemIdentifier: .conversation(1),
        isSingleRecipient: false,
        actionResolverParams: params,
        onActionTap: { _, _ in }
    )
}
