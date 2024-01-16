// Copyright (c) 2022 Proton AG
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
import UIKit

// MARK: Encrypted related variables

extension MessageEntity {
    var isPlainText: Bool {
        mimeType?.lowercased() == Message.MimeType.textPlain.rawValue
    }

    var isMultipartMixed: Bool {
        self.mimeType?.lowercased() == Message.MimeType.multipartMixed.rawValue
    }
}

extension MessageEntity {
    var isSent: Bool {
        self.contains(location: .sent) || self.contains(location: .hiddenSent)
    }

    var isDraft: Bool {
        self.contains(location: .draft) || self.contains(location: .hiddenDraft)
    }

    var isTrash: Bool {
        self.contains(location: .trash)
    }

    var isSpam: Bool {
        self.contains(location: .spam)
    }

    var isStarred: Bool {
        self.contains(location: .starred)
    }

    var isAutoReply: Bool {
        guard !isSent, !isDraft else {
            return false
        }
        let autoReplyKeys = [MessageHeaderKey.autoReply,
                             MessageHeaderKey.autoRespond,
                             MessageHeaderKey.autoReplyFrom,
                             MessageHeaderKey.mailAutoReply]
        return self.parsedHeaders.keys.contains(where: { autoReplyKeys.contains($0) })
    }

    var hasReceiptRequest: Bool {
        self.parsedHeaders
            .keys
            .contains(MessageHeaderKey.dispositionNotificationTo)
    }

    var hasSentReceipt: Bool {
        self.flag.contains(.receiptSent)
    }

    var isReplied: Bool {
        self.flag.contains(.replied)
    }

    var isRepliedAll: Bool {
        self.flag.contains(.repliedAll)
    }

    var isForwarded: Bool {
        self.flag.contains(.forwarded)
    }

    var isScheduledSend: Bool {
        self.flag.contains(.scheduledSend)
    }

    var showReminder: Bool {
        self.flag.contains(.showReminder)
    }

    func isLabelLocation(labelId: LabelID) -> Bool {
        self.labels
            .filter { $0.type == .messageLabel }
            .map(\.labelID)
            .filter { Message.Location($0) == nil }
            .contains(labelId)
    }

    func getFirstValidFolder() -> LabelID? {
        let foldersToFilter = [
            Message.HiddenLocation.sent.rawValue,
            Message.HiddenLocation.draft.rawValue,
            Message.Location.starred.rawValue,
            Message.Location.allmail.rawValue,
            Message.Location.almostAllMail.rawValue
        ]
        for label in labels {
            if label.type == .folder {
                return label.labelID
            }

            if !label.labelID.rawValue.preg_match("(?!^\\d+$)^.+$") {
                if !foldersToFilter.contains(label.labelID.rawValue) {
                    return label.labelID
                }
            }
        }
        return nil
    }

    var isHavingMoreThanOneContact: Bool {
        (recipientsTo + recipientsCc).count > 1
    }
}

extension MessageEntity {
    var messageLocation: LabelLocation? {
        self.orderedLocations
            .first(where: { $0 != .allmail && $0 != .starred })
    }

    private var orderedLocations: [LabelLocation] {
        self.labels
            .filter { $0.type == .folder || Int($0.labelID.rawValue) != nil }
            .compactMap { LabelLocation(labelID: $0.labelID, name: $0.name) }
            .sorted(by: { Int($0.rawLabelID) ?? 0 < Int($1.rawLabelID) ?? 0 })
    }

    var orderedLocation: LabelLocation? {
        self.orderedLocations.first
    }

    var orderedLabel: [LabelEntity] {
        self.labels
            .filter { Int($0.labelID.rawValue) == nil && $0.type == .messageLabel }
            .sorted(by: { $0.order < $1.order })
    }

    var customFolder: LabelEntity? {
        self.labels
            .first(where: { Int($0.labelID.rawValue) == nil && $0.type == .folder })
    }

    var isCustomFolder: Bool {
        self.customFolder != nil
    }

    var allRecipients: [String] {
        return recipientsTo + recipientsCc + recipientsBcc
    }
}

extension MessageEntity {
    func contains(location: LabelLocation) -> Bool {
        self.contains(labelID: location.labelID)
    }

    func contains(labelID: LabelID) -> Bool {
        let labels = self.labels.map(\.labelID)
        return labels.contains(labelID)
    }

    func getLabelIDs() -> [LabelID] {
        return self.labels
            .map(\.labelID)
            .sorted(by: { Int($0.rawValue) ?? 0 < Int($1.rawValue) ?? 0 })
    }

    func getCIDOfInlineAttachment(decryptedBody: String?) -> [String]? {
        guard let body = decryptedBody else {
            return nil
        }
        let cids = attachments
            .compactMap { $0.getContentID() }
            .filter { body.contains(check: $0) }
        return cids
    }

    func attachmentsContainingPublicKey() -> [AttachmentEntity] {
        let largeKeySize = 50 * 1_024
        let publicKeyAttachments = attachments
            .filter { entity in
                entity.name.hasSuffix(".asc") && entity.fileSize.intValue < largeKeySize
            }
        return publicKeyAttachments
    }

    func firstValidFolder() -> LabelID? {
        for label in labels {
            if label.type == .folder {
                return label.labelID
            }

            if !label.labelID.rawValue.preg_match("(?!^\\d+$)^.+$") {
                if label.labelID != "1", label.labelID != "2", label.labelID != "10", label.labelID != "5" {
                    return label.labelID
                }
            }
        }

        return nil
    }

    func parseSender() throws -> Sender {
        guard let rawSender = self.rawSender else {
            throw SenderError.senderStringIsNil
        }
        return try Sender.decodeDictionary(jsonString: rawSender)
    }
}
