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
import proton_app_uniffi
import struct SwiftUI.Color
import class SwiftUI.UIImage

extension Conversation {

    func toMailboxItemCellUIModel(selectedIds: Set<Id>, showLocation: Bool) -> MailboxItemCellUIModel {

        return MailboxItemCellUIModel(
            id: id,
            conversationID: id,
            type: .conversation,
            avatar: avatarUIModelFor(senders: senders),
            emails: senders.addressUIRepresentation,
            subject: subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            locationIcon: showLocation ? exclusiveLocation?.mailboxLocationIcon : nil,
            isRead: numUnread == 0,
            isStarred: isStarred,
            isSelected: selectedIds.contains(id),
            isSenderProtonOfficial: senders.contains(where: \.isProton),
            messagesCount: totalMessages > 1 ? totalMessages : 0,
            labelUIModel: customLabels.toMailboxLabelUIModel(),
            attachmentsUIModel: attachmentsMetadata.toAttachmentCapsuleUIModels(),
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationTime)),
            snoozeDate: nil,
            isDraftMessage: false
        )
    }

    private func avatarUIModelFor(senders: [MessageSender]) -> AvatarUIModel {
        let first = senders.first
        let viewType: AvatarViewType = .sender(
            params: .init(
                address: first?.address ?? .empty,
                bimiSelector: first?.bimiSelector ?? nil,
                displaySenderImage: true
            ))
        return .init(info: avatarInformationFromMessageSenders(addressList: senders).info, type: viewType)
    }
}
