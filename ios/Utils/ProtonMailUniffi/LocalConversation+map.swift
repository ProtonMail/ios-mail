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

extension LocalConversation {

    private func toLabel() -> MailboxLabelUIModel {
        guard
            let labels = self.labels,
            let firstLabel = labels.first
        else { return .init() }
        return .init(
            id: String(firstLabel.id),
            color: Color(hex: firstLabel.color),
            text: firstLabel.name,
            numExtraLabels: labels.count
        )
    }

    func toMailboxConversationCellUIModel(selectedIds: Set<PMMailboxItemId>) -> MailboxConversationCellUIModel {
        MailboxConversationCellUIModel(
            id: id,
            avatar: .init(initials: avatarInformation.text, backgroundColor: Color(hex: avatarInformation.color)),
            senders: senders.uiRepresentation,
            subject: subject,
            date: Date(timeIntervalSince1970: TimeInterval(time)),
            isRead: numUnread == 0,
            isStarred: starred,
            isSelected: selectedIds.contains(id),
            isSenderProtonOfficial: senders.first?.isProton ?? false,
            numMessages: numMessages > 1 ? Int(numMessages) : 0,
            labelUIModel: toLabel(),
            attachmentsUIModel: (attachments ?? []).toAttachmentCapsuleUIModels(),
            expirationDate: Date(timeIntervalSince1970: TimeInterval(expirationTime)),
            snoozeDate: nil
        )
    }
}

private extension Array where Element == MessageAddress {

    var uiRepresentation: String {
        return map {
            !$0.name.isEmpty ? $0.name : $0.address
        }
        .joined(separator: ", ")
    }
}
