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
import proton_app_uniffi
import SwiftUI

extension Message {

    func toMailboxItemCellUIModel(selectedIds: Set<ID>, displaySenderEmail: Bool) -> MailboxItemCellUIModel {
        var recipientsUIRepresentation: String {
            let recipients = (toList + ccList + bccList).map(\.uiRepresentation).joined(separator: ", ")
            return recipients.isEmpty ? L10n.Mailbox.Item.noRecipient.string : recipients
        }

        let emails: String = displaySenderEmail ? sender.uiRepresentation : recipientsUIRepresentation

        return MailboxItemCellUIModel(
            id: id,
            type: .message,
            avatar: toAvatarUIModel(),
            emails: emails,
            subject: subject.isEmpty ? L10n.Mailbox.Item.noSubject.string : subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            isRead: !unread,
            isStarred: starred,
            isSelected: selectedIds.contains(id),
            isSenderProtonOfficial: sender.isProton,
            numMessages: 0,
            labelUIModel: customLabels.toMailboxLabelUIModel(),
            attachmentsUIModel: attachmentsMetadata.toAttachmentCapsuleUIModels(),
            replyIcons: .init(
                shouldShowRepliedIcon: isReplied,
                shouldShowRepliedAllIcon: isRepliedAll,
                shouldShowForwardedIcon: isForwarded
            ),
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationTime)),
            snoozeDate: nil
        )
    }

    func toAvatarUIModel() -> AvatarUIModel {
        .init(
            info: sender.avatarInfo,
            type: .sender(params: .init(
                address: sender.address,
                bimiSelector: sender.bimiSelector,
                displaySenderImage: sender.displaySenderImage
            ))
        )
    }

    func toExpandedMessageCellUIModel(message: String?) -> ExpandedMessageCellUIModel {
        .init(
            id: id,
            message: message,
            messageDetails: MessageDetailsUIModel(
                avatar: toAvatarUIModel(),
                sender: .init(
                    name: sender.uiRepresentation,
                    address: sender.address,
                    encryptionInfo: "End to end encrypted and signed"
                ), // TODO: !!
                isSenderProtonOfficial: sender.isProton,
                recipientsTo: toList.map(\.toRecipient),
                recipientsCc: ccList.map(\.toRecipient),
                recipientsBcc: bccList.map(\.toRecipient),
                date: Date(timeIntervalSince1970: TimeInterval(time)),
                location: exclusiveLocation?.model,
                labels: labels,
                other: other
            )
        )
    }

    func toCollapsedMessageCellUIModel() -> CollapsedMessageCellUIModel {
        .init(
            id: id,
            sender: sender.uiRepresentation,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            recipients: recipients.recipientsUIRepresentation,
            messagePreview: nil,
            isRead: !unread,
            avatar: toAvatarUIModel()
        )
    }

    private var recipients: [MessageDetail.Recipient] {
        let allRecipients = toList + ccList + bccList
        return allRecipients.map(\.toRecipient)
    }

    private var labels: [LabelUIModel] {
        customLabels.map { label in
            LabelUIModel(labelId: label.id, text: label.name, color: .init(hex: label.color.value))
        }
    }

    private var other: [MessageDetail.Other] {
        var result: [MessageDetail.Other] = []

        if starred {
            result.append(.starred)
        }

        return result
    }

}

extension ExclusiveLocation {

    var model: MessageDetail.Location {
        switch self {
        case .inbox:
            .noIconColor(name: L10n.Mailbox.SystemFolder.inbox, icon: DS.Icon.icInbox)
        case .trash:
            .noIconColor(name: L10n.Mailbox.SystemFolder.trash, icon: DS.Icon.icTrash)
        case .archive:
            .noIconColor(name: L10n.Mailbox.SystemFolder.archive, icon: DS.Icon.icArchiveBox)
        case .spam:
            .noIconColor(name: L10n.Mailbox.SystemFolder.spam, icon: DS.Icon.icFire)
        case .snoozed:
            .noIconColor(name: L10n.Mailbox.SystemFolder.snoozed, icon: DS.Icon.icClock)
        case .scheduled:
            .noIconColor(name: L10n.Mailbox.SystemFolder.allScheduled, icon: DS.Icon.icClock)
        case .outbox:
            .noIconColor(name: L10n.Mailbox.SystemFolder.outbox, icon: DS.Icon.icFile)
        case .custom(let name, _, let color):
            .init(name: name.stringResource, icon: DS.Icon.icFolderOpenFilled, iconColor: Color(hex: color.value))
        }
    }



}

private extension MessageDetail.Location {

    static func noIconColor(name: LocalizedStringResource, icon: ImageResource) -> Self {
        .init(name: name, icon: icon, iconColor: nil)
    }

}
