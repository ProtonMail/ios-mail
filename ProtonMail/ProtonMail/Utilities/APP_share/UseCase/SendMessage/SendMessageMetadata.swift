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
import enum ProtonCore_Crypto.Algorithm
import class ProtonCore_DataModel.Key

/// Information needed to compose the final message content to execute a send request
struct SendMessageMetadata {
    /// Encryption keys involved in composing the content of the email to be sent
    let keys: SendMessageKeys

    let messageID: MessageID
    /// Number of seconds before the message expires
    let timeToExpire: Int
    /// Collection of information on how to send the message to each of the recipients
    let recipientSendPreferences: [RecipientSendPreferences]
    /// Key used in the `encryptedBody`
    let bodySessionKey: Data
    /// Encryption algorithm used in the `encryptedBody`
    let bodySessionAlgorithm: Algorithm
    /// Message body encrypted. In Proton mesasges to be sent come from `drafts` and
    /// drafts are always stored encrypted. That's why we have an encrypted in this send metadata.
    let encryptedBody: Data
    /// Message body in plain text. Only needed when there is a recipient that requires it
    let decryptedBody: String?
    /// Information for the message attachments
    let attachments: [PreAttachment]
    /// Collection formed by the attachments encoded in base64 ready for the Mime format
    let encodedAttachments: [AttachmentID: String]

    // MARK: Encrypt to outside attributes

    /// Password used to encrypt the message to a non Proton email account
    let password: String?
    /// Hint used to help the receiver of a password protected email to decrypt it
    let passwordHint: String?
}

struct SendMessageKeys {
    /// Address key of the email account sending the message
    let senderAddressKey: Key
    let userKeys: UserKeys
}
