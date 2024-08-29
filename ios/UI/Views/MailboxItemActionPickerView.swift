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
    @State private(set) var highlightedAction: Action? = nil

    private let mailboxItemIdentifier: MailboxItemIdentifier
    private let resolver: MailboxItemActionResolver

    var onActionTap: (_ action: Action, _ item: MailboxItemIdentifier) -> ()

    init(
        mailboxItemIdentifier: MailboxItemIdentifier,
        actionResolverParams: ConditionalActionResolverParams,
        onActionTap: @escaping (_ action: Action, _ item: MailboxItemIdentifier) -> ()
    ) {
        self.mailboxItemIdentifier = mailboxItemIdentifier
        self.resolver = MailboxItemActionResolver(params: actionResolverParams)
        self.onActionTap = onActionTap
    }

    var body: some View {
        ClosableScreen(topSpacing: -DS.Spacing.standard) {
            ActionPickerList(
                headerContent: {
                    replyActionButtons
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                },
                sections: [
                    MailboxItemActionPickerSection.first.actions(type: mailboxItemIdentifier.type).map(resolver.action(for:)),
                    MailboxItemActionPickerSection
                        .second(isSpamFolder: resolver.params.systemFolder.isSpam)
                        .actions(type: mailboxItemIdentifier.type)
                        .map(resolver.action(for:)),
                    MailboxItemActionPickerSection.third.actions(type: mailboxItemIdentifier.type).map(resolver.action(for:))
                ],
                onElementTap: { action in
                    onActionTap(action, mailboxItemIdentifier)
                })
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder
    private var replyActionButtons: some View {
        if mailboxItemIdentifier.type == .conversation {
            EmptyView()
        } else {

            HStack {
                replyActionButton(name: L10n.Action.Send.reply, icon: DS.Icon.icReply)
                    .accessibilityIdentifier(MailboxItemActionPickerIdentifiers.composeActionReply)
                replyActionButton(name: L10n.Action.Send.replyAll, icon: DS.Icon.icReplyAll)
                    .accessibilityIdentifier(MailboxItemActionPickerIdentifiers.composeActionReplyAll)
                replyActionButton(name: L10n.Action.Send.forward, icon: DS.Icon.icForward)
                    .accessibilityIdentifier(MailboxItemActionPickerIdentifiers.composeActionForward)
            }
            .clipped()
        }
    }

    private func replyActionButton(name: LocalizedStringResource, icon: ImageResource) -> some View {
        Button {

        } label: {
            SendActionButtonStack() {
                Image(icon)
                    .actionSheetIconModifier()
                    .accessibilityIdentifier(MailboxItemActionPickerIdentifiers.composeActionIcon)

                Text(name)
                    .lineLimit(1)
                    .fontBody3()
                    .foregroundStyle(DS.Color.Text.weak)
                    .accessibilityIdentifier(MailboxItemActionPickerIdentifiers.composeActionText)
            }
        }
        .buttonStyle(RegularButtonStyle())
        .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
    }
}

private enum MailboxItemActionPickerSection {

    case first
    case second(isSpamFolder: Bool)
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
        case .second(let isSpamFolder):
            if isSpamFolder {
                [
                    .action(.moveToInboxFromSpam),
                    .action(.moveToTrash),
                    .action(.deletePermanently),
                    .action(.moveTo)
                ]
            }
            else {
                [
                    .conditional(.moveToTrash),
                    .conditional(.moveToArchiveWithTrashFolderCondition),
                    .action(.moveToSpam),
                    .action(.moveTo)
                ]
            }
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

private extension SystemFolderLabel? {

    var isSpam: Bool {
        guard let self = self else { return false }
        return self == .spam
    }
}

private struct SendActionButtonStack<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: DS.Spacing.standard, content: content)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
    }
}

#Preview("Message and multiple recipients") {
    let params = ConditionalActionResolverParams(
        selectionReadStatus: .noneRead,
        selectionStarStatus: .noneStarred,
        systemFolder: nil
    )
    return MailboxItemActionPickerView(
        mailboxItemIdentifier: .message(.init(value: 1)),
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
        mailboxItemIdentifier: .conversation(.init(value: 1)),
        actionResolverParams: params,
        onActionTap: { _, _ in }
    )
}

struct MailboxItemActionPickerIdentifiers {
    static let composeActionsRootItem = "actionPicker.compose"
    static let composeActionReply = "actionPicker.compose.reply"
    static let composeActionReplyAll = "actionPicker.compose.replyAll"
    static let composeActionForward = "actionPicker.compose.forward"
    static let composeActionIcon = "actionPicker.compose.icon"
    static let composeActionText = "actionPicker.compose.text"
}
