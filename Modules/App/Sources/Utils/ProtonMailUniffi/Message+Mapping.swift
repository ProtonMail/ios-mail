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

extension Message {

    var allRecipients: [MessageRecipient] {
        toList + ccList + bccList
    }

    func toMailboxItemCellUIModel(selectedIds: Set<ID>, displaySenderEmail: Bool, showLocation: Bool) -> MailboxItemCellUIModel {
        var recipientsUIRepresentation: String {
            let recipients = allRecipients.map(\.uiRepresentation).joined(separator: ", ")
            return recipients.isEmpty ? L10n.Mailbox.Item.noRecipient.string : recipients
        }

        let emails: String = displaySenderEmail ? sender.uiRepresentation : recipientsUIRepresentation
        let avatar = displaySenderEmail ? sender.senderAvatar : allRecipientsAvatar

        return MailboxItemCellUIModel(
            id: id,
            conversationID: conversationId,
            type: .message,
            avatar: avatar,
            emails: emails,
            subject: subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            exclusiveLocation: exclusiveLocation,
            locationIcon: showLocation ? exclusiveLocation?.mailboxLocationIcon : nil,
            isRead: !unread,
            isStarred: starred,
            isSelected: selectedIds.contains(id),
            isSenderProtonOfficial: sender.isProton,
            messagesCount: 0,
            labelUIModel: customLabels.toMailboxLabelUIModel(),
            attachments: .init(
                previewables: attachmentsMetadata.toAttachmentCapsuleUIModels(),
                containsCalendarInvitation: attachmentsMetadata.hasICS,
                totalCount: Int(numAttachments)
            ),
            replyIcons: .init(
                shouldShowRepliedIcon: isReplied,
                shouldShowRepliedAllIcon: isRepliedAll,
                shouldShowForwardedIcon: isForwarded
            ),
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationTime)),
            snoozeDate: snoozedUntil.map(TimeInterval.init).map(Date.init(timeIntervalSince1970:)),
            isDraftMessage: isDraft,
            shouldUseSnoozedColorForDate: displaySnoozeReminder
        )
    }

    func toExpandedMessageCellUIModel() -> ExpandedMessageCellUIModel {
        .init(
            id: id,
            unread: unread,
            messageDetails: MessageDetailsUIModel(
                id: id,
                avatar: sender.senderAvatar,
                sender: .init(
                    name: sender.uiRepresentation,
                    address: sender.address,
                    encryptionInfo: "End to end encrypted and signed"
                ),  // TODO: !!
                isSenderProtonOfficial: sender.isProton,
                recipientsTo: toList.map(\.toRecipient),
                recipientsCc: ccList.map(\.toRecipient),
                recipientsBcc: bccList.map(\.toRecipient),
                date: Date(timeIntervalSince1970: TimeInterval(time)),
                location: exclusiveLocation?.model,
                labels: labels,
                attachments: attachmentsMetadata.map(\.displayModel),
                isStarred: starred,
                showPaperClip: showPaperClip
            )
        )
    }

    func toCollapsedMessageCellUIModel() -> CollapsedMessageCellUIModel {
        .init(
            sender: sender.uiRepresentation,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            recipients: recipients,
            isRead: !unread,
            isDraft: isDraft,
            isStarred: starred,
            showPaperClip: showPaperClip,
            avatar: sender.senderAvatar
        )
    }

    private var showPaperClip: Bool {
        numAttachments > 0
    }

    private var recipients: [MessageDetail.Recipient] {
        allRecipients.map(\.toRecipient)
    }

    private var labels: [LabelUIModel] {
        customLabels.map { label in
            LabelUIModel(labelId: label.id, text: label.name, color: .init(hex: label.color.value))
        }
    }

    private var allRecipientsAvatar: AvatarUIModel {
        let avatarInformation = avatarInformationFromMessageRecipients(addressList: allRecipients)

        return .init(info: avatarInformation.info, type: .other)
    }

}

private extension AttachmentMetadata {

    var displayModel: AttachmentDisplayModel {
        .init(id: id, mimeType: mimeType, name: name, size: size)
    }

}
