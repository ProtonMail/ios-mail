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

extension Conversation {

    func toMailboxItemCellUIModel(selectedIds: Set<Id>) async -> MailboxItemCellUIModel {
        let firstSender = senders.first.unsafelyUnwrapped
        let senderImage = await Caches.senderImageCache.object(for: firstSender.address)
        let avatarInformation = avatarInformationFromMessageAddress(address: firstSender)

        return MailboxItemCellUIModel(
            id: id,
            type: .conversation,
            avatar: .init(
                initials: avatarInformation.text,
                senderImage: senderImage,
                backgroundColor: Color(hex: avatarInformation.color),
                type: .sender(params: .init(
                    address: firstSender.address,
                    bimiSelector: firstSender.bimiSelector,
                    displaySenderImage: firstSender.displaySenderImage
                ))
            ),
            senders: senders.addressUIRepresentation,
            subject: subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            isRead: numUnread == 0,
            isStarred: isStarred,
            isSelected: selectedIds.contains(id),
            isSenderProtonOfficial: firstSender.isProton,
            numMessages: numMessages > 1 ? numMessages : 0,
            labelUIModel: customLabels.toMailboxLabelUIModel(),
            attachmentsUIModel: attachmentsMetadata.toAttachmentCapsuleUIModels(),
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationTime)),
            snoozeDate: nil
        )
    }

}
