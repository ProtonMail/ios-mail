// Copyright (c) 2022 Proton Technologies AG
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
import GoLibs

class EncryptedSearchDecryptedMessageContent: EncryptedsearchDecryptedMessageContent {
    init?(
        _ subjectValue: String?,
        bodyValue: String?,
        senderValue: EncryptedSearchRecipient?,
        toListValue: EncryptedSearchRecipientList?,
        ccListValue: EncryptedSearchRecipientList?,
        bccListValue: EncryptedSearchRecipientList?,
        addressID: String?,
        conversationID: String?,
        flags: Int,
        unread: Bool,
        isStarred: Bool,
        isReplied: Bool,
        isRepliedAll: Bool,
        isForwarded: Bool,
        numAttachments: Int,
        expirationTime: Int
    ) {
        super.init(subjectValue,
                   senderValue: senderValue,
                   bodyValue: bodyValue,
                   toListValue: toListValue,
                   ccListValue: ccListValue,
                   bccListValue: bccListValue,
                   addressID: addressID,
                   conversationID: conversationID,
                   flags: Int64(flags),
                   unread: unread,
                   isStarred: isStarred,
                   isReplied: isReplied,
                   isRepliedAll: isRepliedAll,
                   isForwarded: isForwarded,
                   numAttachments: numAttachments,
                   expirationTime: Int64(expirationTime))
    }
}
