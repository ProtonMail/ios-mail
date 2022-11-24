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
    var isInternal: Bool {
        self.flag.contains(.internal) && self.flag.contains(.received)
    }

    var isExternal: Bool {
        !self.flag.contains(.internal) && self.flag.contains(.received)
    }

    var isE2E: Bool {
        self.flag.contains(.e2e)
    }

    var isSignedMime: Bool {
        isMultipartMixed && isExternal && !isE2E
    }

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

    var isNewsLetter: Bool {
        let newsLetterKeys = [
            MessageHeaderKey.listID,
            MessageHeaderKey.listUnsubscribe,
            MessageHeaderKey.listSubscribe,
            MessageHeaderKey.listPost,
            MessageHeaderKey.listHelp,
            MessageHeaderKey.listOwner,
            MessageHeaderKey.listArchive
        ]
        return self.parsedHeaders.keys.contains(where: { newsLetterKeys.contains($0) })
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
            Message.Location.allmail.rawValue
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
        return recipientsTo + recipientsTo + recipientsBcc
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
}

// MARK: - Sender related

extension MessageEntity {

    func getInitial(senderName: String) -> String {
        return senderName.isEmpty ? "?" : senderName.initials()
    }

    func getSender(senderName: String) -> String {
        return senderName.isEmpty ? "(\(String(format: LocalString._mailbox_no_recipient)))" : senderName
    }

    func getSenderName(replacingEmailsMap: [String: EmailEntity], groupContacts: [ContactGroupVO]) -> String {
        if isSent || isDraft || isScheduledSend {
            return allEmailAddresses(replacingEmailsMap, allGroupContacts: groupContacts)
        } else {
            return displaySender(replacingEmailsMap)
        }
    }

    // Although the time complexity of high order function is O(N)
    // But keep in mind that tiny O(n) can add up to bigger blockers if you accumulate them
    // Do async approach when there is a performance issue
    private func allEmailAddresses(
        _ replacingEmails: [String: EmailEntity],
        allGroupContacts: [ContactGroupVO]
    ) -> String {
        var recipientLists = ContactPickerModelHelper.contacts(from: rawTOList)
        + ContactPickerModelHelper.contacts(from: rawCCList)
        + ContactPickerModelHelper.contacts(from: rawBCCList)

        let groups = recipientLists.compactMap { $0 as? ContactGroupVO }
        var groupList: [String] = []
        if !groups.isEmpty {
            groupList = self.getGroupNameLists(group: groups,
                                               allGroupContacts: allGroupContacts)
        }
        recipientLists = recipientLists.filter { ($0 as? ContactGroupVO) == nil }

        let lists: [String] = recipientLists.map { recipient in
            let address = recipient.displayEmail ?? ""
            let name = recipient.displayName ?? ""
            let email = replacingEmails[address]
            let emailName = email?.name ?? ""
            let displayName = emailName.isEmpty ? name : emailName
            return displayName.isEmpty ? address : displayName
        }
        let result = groupList + lists
        return result.isEmpty ? "" : result.asCommaSeparatedList(trailingSpace: true)
    }

    private func getGroupNameLists(group: [ContactGroupVO],
                                   allGroupContacts: [ContactGroupVO]) -> [String] {
        var nameList: [String] = []
        group.forEach { group in
            let groupName = group.contactTitle
            // Get total count of this ContactGroup
            let totalContactCount = allGroupContacts
                .first(where: { $0.contactTitle == group.contactTitle })?.contactCount ?? 0
            let name = "\(groupName) (\(group.contactCount)/\(totalContactCount))"
            nameList.append(name)
        }
        return nameList
    }

    func displaySender(_ replacingEmails: [String: EmailEntity]) -> String {
        guard let sender = sender else {
            assertionFailure("Sender with no name or address")
            return ""
        }

        guard let email = replacingEmails[sender.email] else {
            return sender.name.isEmpty ? sender.email : sender.name
        }

        if !email.contactName.isEmpty {
            return email.contactName
        } else if !email.name.isEmpty {
            return email.name
        } else if let displayName = sender.displayName, !displayName.isEmpty {
            return displayName
        } else {
            return sender.email
        }
    }
}
