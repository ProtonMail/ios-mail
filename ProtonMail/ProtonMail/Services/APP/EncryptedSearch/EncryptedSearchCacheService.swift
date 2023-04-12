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

final class EncryptedSearchCacheService {
    enum Constant {
        // Percentage of heap that can be used by the cache
        static let searchCacheHeapPercent: Double = 0.2
        // Percentage of heap that can be used to load messages from the index
        static let searchBatchHeapPercent: Double = 0.1
        // An estimation of how many bytes take a search message in memory
        static let searchMsgSize: Double = 14_000
    }

    private let maxCacheSize: Int
    private let batchSize: Int
    private var cache: EncryptedSearchGolangCacheProtocol
    private let userID: UserID

    init?(userID: UserID, memoryUsage: MemoryUsageProtocol = DeviceCapacity.Memory()) {
        self.userID = userID
        let maxMemory = memoryUsage.physicalMemory - memoryUsage.used
        let maxCacheSizeDouble = Double(maxMemory) * Constant.searchCacheHeapPercent
        self.maxCacheSize = Int(maxCacheSizeDouble)
        self.batchSize = Int(maxCacheSizeDouble / Constant.searchMsgSize)
        if let cache = EncryptedSearchGolangCacheService(Int64(self.maxCacheSize)) {
            self.cache = cache
        } else {
            return nil
        }
    }

    func buildCacheForUser(
        dbParams: EncryptedSearchDBParams,
        cipher: EncryptedSearchAESGCMCipher
    ) -> EncryptedSearchGolangCacheProtocol? {
        self.cache.deleteAll()
        do {
            try self.cache.cacheIndexIntoDB(
                dbParams: dbParams,
                cipher: cipher,
                batchSize: Int(self.batchSize)
            )
        } catch {
            print("Error when building the cache: ", error)
        }
        return self.cache
    }

    func deleteCache() {
        cache.deleteAll()
    }

    func updateCachedMessage(message: MessageEntity, decryptedBody: String) {
        let msgToInsert: EncryptedSearchMessage? = self.messageToEncryptedSearchMessage(
            msg: message,
            decryptedBody: decryptedBody
        )
        cache.updateCache(messageToInsert: msgToInsert)
    }

    func deleteCachedMessage(messageID: MessageID) -> Bool {
        return cache.deleteMessage(messageID.rawValue)
    }

    func isCacheBuilt() -> Bool {
        return cache.isBuilt()
    }

    private func messageToEncryptedSearchMessage(
        msg: MessageEntity,
        decryptedBody: String?
    ) -> EncryptedSearchMessage? {
        let emailContent = EmailparserExtractData(decryptedBody, true)
        let encryptedContent = EncryptedSearchHelper.createEncryptedMessageContent(
            from: msg,
            cleanedBody: emailContent,
            userID: userID
        )

        guard let msgSender = try? msg.parseSender() else {
            return nil
        }

        let sender = EncryptedSearchRecipient(msgSender.name,
                                              email: msgSender.address)

        let toList = transferToESRecipientList(rawRecipientList: msg.rawTOList, type: .to)
        let ccList = transferToESRecipientList(rawRecipientList: msg.rawCCList, type: .cc)
        let bccList = transferToESRecipientList(rawRecipientList: msg.rawBCCList, type: .bcc)

        let decryptedMessageContent = EncryptedSearchDecryptedMessageContent(
            msg.title,
            bodyValue: emailContent,
            senderValue: sender,
            toListValue: toList,
            ccListValue: ccList,
            bccListValue: bccList,
            addressID: msg.addressID.rawValue,
            conversationID: msg.conversationID.rawValue,
            flags: msg.rawFlag,
            unread: msg.unRead,
            isStarred: msg.isStarred,
            isReplied: msg.isReplied,
            isRepliedAll: msg.isRepliedAll,
            isForwarded: msg.isForwarded,
            numAttachments: msg.numAttachments,
            expirationTime: Int(msg.expirationTime?.timeIntervalSince1970 ?? 0)
        )

        return EncryptedSearchMessage(
            msg.messageID.rawValue,
            timeValue: Int(msg.time?.timeIntervalSince1970 ?? 0),
            orderValue: msg.order,
            labelIDsValue: msg.getLabelIDs().map(\.rawValue).joined(separator: ","),
            encryptedValue: encryptedContent,
            decryptedValue: decryptedMessageContent
        )
    }

    private enum RecipientType {
        case to, cc, bcc

        var description: String {
            switch self {
            case .to:
                return "message.toList"
            case .cc:
                return "message.ccList"
            case .bcc:
                return "message.bccList"
            }
        }
    }

    private func transferToESRecipientList(
        rawRecipientList: String,
        type: RecipientType
    ) -> EncryptedSearchRecipientList {
        let esRecipientList = EncryptedSearchRecipientList()
        guard let listData: Data = rawRecipientList.data(using: .utf8) else { return esRecipientList }
        do {
            let decoder = JSONDecoder()
            let esSenderList = try decoder.decode([Sender].self, from: listData)

            esSenderList.forEach { recipient in
                esRecipientList.add(user: EncryptedSearchRecipient(recipient.name, email: recipient.address))
            }
            return esRecipientList
        } catch {
            print("Error when decoding \(type.description)")
            return esRecipientList
        }
    }

    #if DEBUG
    func setCache(_ cache: EncryptedSearchGolangCacheProtocol) {
        self.cache = cache
    }
    #endif
}
