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
        if let mime = self.mimeType,
           mime.lowercased() == MIMEType.txtMIME {
            return true
        }
        return false
    }

    var isMultipartMixed: Bool {
        self.mimeType?.lowercased() == MIMEType.multipartMixedMIME
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

            if !label.labelID.rawValue.preg_match ("(?!^\\d+$)^.+$") {
                if !foldersToFilter.contains(label.labelID.rawValue) {
                    return label.labelID
                }
            }
        }
        return nil
    }

    var isHavingMoreThanOneContact: Bool {
        (toList + ccList).count > 1
    }
}

extension MessageEntity {
    var messageLocation: LabelLocation? {
        self.labels
            .compactMap { LabelLocation.init(labelID: $0.labelID, name: $0.name) }
            .first(where: { $0 != .allmail && $0 != .starred })
    }

    var orderedLocation: LabelLocation? {
        self.labels
            .compactMap { LabelLocation.init(labelID: $0.labelID, name: $0.name) }
            .min { Int($0.rawLabelID) ?? 0 < Int($1.rawLabelID) ?? 0 }
    }

    var orderedLabel: [LabelEntity] {
        self.labels
            .filter({ Int($0.labelID.rawValue) == nil && $0.type == .messageLabel })
            .sorted(by: { $0.order < $1.order })
    }

    var customFolder: LabelEntity? {
        self.labels
            .filter({ Int($0.labelID.rawValue) == nil })
            .first(where: { $0.type == .folder })
    }

    var isCustomFolder: Bool {
        self.customFolder != nil
    }

    var allRecipients: [ContactPickerModelProtocol] {
        self.toList + self.ccList + self.bccList
    }

    var htmlBody: String {
        if isPlainText {
            return "<div>" + body.ln2br() + "</div>"
        } else {
            let body_without_ln = body.rmln()
            return "<div><pre>" + body_without_ln.lr2lrln() + "</pre></div>"
        }
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
        return self.labels.map(\.labelID)
    }

    func getInboxType() -> PGPType {
        guard self.isDetailDownloaded else { return .none }

        if self.isInternal { return .internal_normal }

        //outPGPInline, outPGPMime
        if isE2E { return .pgp_encrypted }

        //outSignedPGPMime
        if isSignedMime { return .zero_access_store }

        if self.isExternal { return .zero_access_store }

        return .none
    }

    func getCIDOfInlineAttachment(decryptedBody: String?) -> [String]? {
        guard let body = decryptedBody else {
            return nil
        }
        let cids = attachments
            .compactMap({ $0.getContentID() })
            .filter { body.contains(check: $0) }
        return cids
    }
}

// MARK: - Sender related
extension MessageEntity {
    var recipients: [ContactPickerModelProtocol] {
        return self.toList + self.ccList + self.bccList
    }

    func getInitial(replacingEmails: [Email], groupContacts: [ContactGroupVO]) -> String {
        let senderName = self.getSenderName(replacingEmails: replacingEmails, groupContacts: groupContacts)
        return senderName.isEmpty ? "?" : senderName.initials()
    }

    func getSender(replacingEmails: [Email],
                   groupContacts: [ContactGroupVO]) -> String {
        let senderName = self.getSenderName(replacingEmails: replacingEmails, groupContacts: groupContacts)
        return senderName.isEmpty ? "(\(String(format: LocalString._mailbox_no_recipient)))" : senderName
    }

    func getSenderName(replacingEmails: [Email],
                       groupContacts: [ContactGroupVO]) -> String {
        if isSent || isDraft {
            return allEmailAddresses(replacingEmails, allGroupContacts: groupContacts)
        } else {
            return displaySender(replacingEmails)
        }
    }
    // Although the time complexity of high order function is O(N)
    // But keep in mind that tiny O(n) can add up to bigger blockers if you accumulate them
    // Do async approach when there is a performance issue
    private func allEmailAddresses(_ replacingEmails: [Email],
                           allGroupContacts: [ContactGroupVO]) -> String {
        var recipientLists = self.recipients
        let groups = recipientLists.compactMap{ $0 as? ContactGroupVO }
        var groupList: [String] = []
        if !groups.isEmpty {
            groupList = self.getGroupNameLists(group: groups,
                                               allGroupContacts: allGroupContacts)
        }
        recipientLists = recipientLists.filter{ ($0 as? ContactGroupVO) == nil }

        let lists: [String] = recipientLists.map { recipient in
            let address = recipient.displayEmail ?? ""
            let name = recipient.displayName ?? ""
            let email = replacingEmails.first(where: { $0.email == address })
            let emailName = email?.name ?? ""
            let displayName = emailName.isEmpty ? name: emailName
            return displayName.isEmpty ? address: displayName
        }
        let result = groupList + lists
        return result.isEmpty ? "": result.asCommaSeparatedList(trailingSpace: true)
    }

    private func getGroupNameLists(group: [ContactGroupVO],
                                   allGroupContacts: [ContactGroupVO]) -> [String] {
        var nameList: [String] = []
        group.forEach { group in
            let groupName = group.contactTitle
            // Get total count of this ContactGroup
            let totalContactCount = allGroupContacts.first(where: { $0.contactTitle == group.contactTitle })?.contactCount ?? 0
            let name = "\(groupName) (\(group.contactCount)/\(totalContactCount))"
            nameList.append(name)
        }
        return nameList
    }

    func displaySender(_ replacingEmails: [Email]) -> String {
        guard let sender = sender else {
            assert(false, "Sender with no name or address")
            return ""
        }

        // will this be deadly slow?
        let mails = replacingEmails.filter({ $0.email == sender.email })
            .sorted { mail1, mail2 in
                guard let time1 = mail1.contact.createTime,
                      let time2 = mail2.contact.createTime else {
                          return true
                      }
                return time1 < time2
            }
        if mails.isEmpty {
            return sender.name.isEmpty ? sender.email : sender.name
        }
        let contact = mails[0].contact
        return contact.name.isEmpty ? mails[0].name: contact.name
    }
}
