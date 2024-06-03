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

import Foundation
import proton_mail_uniffi
import struct SwiftUI.Color
import class SwiftUI.UIImage

extension LocalMessageMetadata {

    func toMailboxItemCellUIModel(selectedIds: Set<PMMailboxItemId>) async -> MailboxItemCellUIModel {
        let senderImage: UIImage? = await Caches.senderImageCache.object(for: sender.address)

        return MailboxItemCellUIModel(
            id: id,
            type: .message,
            avatar: .init(
                initials: avatarInformation.text,
                senderImage: senderImage,
                senderImageParams: .init(
                    address: sender.address,
                    bimiSelector: sender.bimiSelector,
                    displaySenderImage: sender.displaySenderImage
                ),
                backgroundColor: Color(hex: avatarInformation.color)
            ),
            senders: sender.uiRepresentation,
            subject: subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            isRead: !unread,
            isStarred: starred,
            isSelected: selectedIds.contains(id),
            isSenderProtonOfficial: sender.isProton,
            numMessages: 0,
            labelUIModel: labels?.toMailboxLabelUIModel() ?? .init(),
            attachmentsUIModel: (attachments ?? []).toAttachmentCapsuleUIModels(),
            replyIcons: .init(
                shouldShowRepliedIcon: isReplied,
                shouldShowRepliedAllIcon: isRepliedAll,
                shouldShowForwardedIcon: isForwarded
            ),
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationTime)),
            snoozeDate: nil
        )
    }
}

extension LocalMessageMetadata {

    func toCollapsedMessageCellUIModel() async -> CollapsedMessageCellUIModel {
        .init(
            messageId: id,
            sender: sender.uiRepresentation,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            recipients: recipientsUIRepresentation,
            messagePreview: nil,
            isRead: !unread,
            avatar: await toAvatarUIModel()
        )
    }
}

extension LocalMessageMetadata {

    func toExpandedMessageCellUIModel(message: String) async -> ExpandedMessageCellUIModel {
        .init(
            messageId: id,
            message: message,
            sender: sender.uiRepresentation,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            senderPrivacy: sender.address,
            recipients: recipientsUIRepresentation,
            isSingleRecipient: numberOfRecipients == 1,
            avatar: await toAvatarUIModel()
        )
    }
}
