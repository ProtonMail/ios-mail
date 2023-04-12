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

enum EncryptedSearchHelper {
    static func createEncryptedMessageContent(
        from message: MessageEntity,
        cleanedBody: String,
        userID: UserID
    ) -> EncryptedSearchEncryptedMessageContent? {
        guard let msgSender = try? message.parseSender() else {
            return nil
        }
        let sender = EncryptedSearchRecipient(msgSender.name, email: msgSender.address)

        let toList = EncryptedSearchRecipientList()
        if let toListJsonDict = message.rawTOList.parseJson() {
            toListJsonDict.forEach { contact in
                let recipient = EncryptedSearchRecipient(contact["Name"] as? String ?? "",
                                                         email: contact["Address"] as? String ?? "")
                toList.add(user: recipient)
            }
        }
        let ccList = EncryptedSearchRecipientList()
        if let ccListJsonDict = message.rawCCList.parseJson() {
            ccListJsonDict.forEach { contact in
                let recipient = EncryptedSearchRecipient(contact["Name"] as? String ?? "",
                                                         email: contact["Address"] as? String ?? "")
                ccList.add(user: recipient)
            }
        }
        let bccList = EncryptedSearchRecipientList()
        if let bccListJsonDict = message.rawBCCList.parseJson() {
            bccListJsonDict.forEach { contact in
                let recipient = EncryptedSearchRecipient(contact["Name"] as? String ?? "",
                                                         email: contact["Address"] as? String ?? "")
                bccList.add(user: recipient)
            }
        }

        let decryptedMessageContent = EncryptedSearchDecryptedMessageContent(
            message.title,
            bodyValue: cleanedBody,
            senderValue: sender,
            toListValue: toList,
            ccListValue: ccList,
            bccListValue: bccList,
            addressID: message.addressID.rawValue,
            conversationID: message.conversationID.rawValue,
            flags: message.flag.rawValue,
            unread: message.unRead,
            isStarred: message.isStarred,
            isReplied: message.isReplied,
            isRepliedAll: message.isRepliedAll,
            isForwarded: message.isForwarded,
            numAttachments: message.numAttachments,
            expirationTime: Int(message.expirationTime?.timeIntervalSince1970 ?? 0)
        )

        let cipher = Self.getEncryptedCipher(userID: userID)
        var encryptedMessageContent: EncryptedSearchEncryptedMessageContent?

        encryptedMessageContent = try? cipher?.encrypt(decryptedMessageContent)

        return encryptedMessageContent
    }

    static func getEncryptedCipher(userID: UserID) -> EncryptedSearchAESGCMCipher? {
        var cipher: EncryptedSearchAESGCMCipher?
        let key = retrieveSearchIndexKey(userID: userID)
        guard let key = key else {
            return nil
        }
        cipher = EncryptedSearchAESGCMCipher(key)
        return cipher
    }

    static func generateSearchIndexKey(userID: UserID) -> Data? {
        let keyLength: Int = 32
        var error: NSError?
        let bytes: Data? = CryptoRandomToken(keyLength, &error)

        if let key = bytes {
            // Add search index key to KeyChain
            KeychainWrapper.keychain.set(key, forKey: "searchIndexKey_" + userID.rawValue)
            return key
        } else {
            print("Error when generating search index key!")
            return nil
        }
    }

    static func retrieveSearchIndexKey(userID: UserID) -> Data? {
        var key: Data? = KeychainWrapper.keychain.data(forKey: "searchIndexKey_" + userID.rawValue)
        // Check if user already has an key - otherwise generate one
        if key == nil {
            key = self.generateSearchIndexKey(userID: userID)
        }
        return key
    }
}
